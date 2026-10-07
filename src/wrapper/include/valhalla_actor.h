#ifndef VALHALLAACTOR_H
#define VALHALLAACTOR_H

#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <stdexcept>
#include <string>
#include <valhalla/tyr/actor.h>
#include <valhalla/baldr/tilegetter.h>

class ValhallaMobileHttpClient {
public:
    virtual ~ValhallaMobileHttpClient() = default;
    
    /**
     * Makes a synchronous GET request to fetch tile data
     * @param url the URL to fetch
     * @param range_offset offset for range requests
     * @param range_size size for range requests, or 0 for the whole resource
     * @param accept_gzip whether a gzip body is acceptable (whole tiles with tile_url_gz on)
     * @return GET_response_t with the response data and status
     */
    virtual valhalla::baldr::tile_getter_t::GET_response_t
    get(const std::string& url, uint64_t range_offset, uint64_t range_size, bool accept_gzip) = 0;
    
    /**
     * Makes a synchronous HEAD request to fetch response headers
     * @param url the URL to query
     * @param header_mask mask for which headers to retrieve
     * @return HEAD_response_t with the response headers and status
     */
    virtual valhalla::baldr::tile_getter_t::HEAD_response_t 
    head(const std::string& url, valhalla::baldr::tile_getter_t::header_mask_t header_mask) = 0;
};

/**
 * Owns one Valhalla actor and runs actions against it.
 *
 * Every action runs on a dedicated thread with a 16 MB stack, joined before the call
 * returns: Valhalla's map matcher recurses once per matched edge, which overflows the
 * ~1 MB stack a mobile worker thread has on a long trace. The recursion is unbounded, so
 * this raises the ceiling rather than removing it. Actions stay synchronous, and anything
 * Valhalla calls back out of an action runs on that thread too — see valhalla_actor.cpp.
 *
 * The actor is not safe to use from several threads at once, and this class does not make
 * it so; the Kotlin and Obj-C wrappers serialize calls.
 */
class ValhallaActor {
private:
    /// Passed to every action, so a [cancel] stops a path search as well as a fetch: thor
    /// runs it every few thousand steps. Throwing is how it stops one.
    ///
    /// This, [before_fetch], [fetch_time] and [fetch_failures] are declared before the reader
    /// and the actor, which hold pointers to them, so they are destroyed after them.
    std::function<void()> interrupt;
    /// Run by the tile getter before every request: [interrupt], then the deadline.
    ///
    /// The deadline is checked here and not in [interrupt] because it bounds fetching. A
    /// slow path search over tiles already on disk is not a tile server that has gone away.
    std::function<void()> before_fetch;
    /// How long the running action has spent fetching so far. The tile getter adds each
    /// request's time to it.
    std::atomic<std::chrono::steady_clock::rep> fetch_time{0};
    /// Fetches that failed other than with a 404 or 410, counted by the tile getter.
    std::atomic<uint32_t> fetch_failures{0};

    std::unique_ptr<valhalla::tyr::actor_t> actor;
    std::unique_ptr<valhalla::baldr::GraphReader> graph_reader;

    /**
     * Seconds an action may spend fetching tiles, from `mjolnir.tile_url_timeout`, or 0 for
     * no limit.
     *
     * This is not the same as an HTTP timeout and does not replace one. A platform client
     * gives up on a request after 10 s without data; one route attempts tile after tile,
     * each paying that in turn. Measured against a dead origin on an iOS simulator: 170
     * seconds, during which the app looks frozen. A download that keeps trickling is
     * bounded only by the link.
     *
     * Only time spent in requests counts, so a long path search between them does not use
     * it up. Checked before each tile fetch, so the granularity is one request. A fetch
     * already in flight when the budget runs out is not cancelled -- it finishes or hits its
     * own timeout, and the next one throws. Connect and DNS stalls are the platform client's
     * business; this bounds how many of them an action can accumulate.
     */
    double tile_fetch_timeout_seconds = 0.0;
    /// [tile_fetch_timeout_seconds] in steady_clock ticks, or 0 for no limit. Set at the start
    /// of every action.
    std::atomic<std::chrono::steady_clock::rep> fetch_budget{0};
    /// Why the running action was stopped.
    enum class Stop : uint8_t { none, timed_out, cancelled };
    /// Set when [interrupt] or [before_fetch] stops an action, cleared when one is armed.
    ///
    /// The exception they throw does not always reach the caller: loki catches anything a
    /// tile fetch throws during its search and reports "No suitable edges near location"
    /// (error 171) -- the same answer a genuinely unroutable address gives. Recording the
    /// stop is how an action that gave up is told apart from one that looked and found
    /// nothing. The first reason is kept, and it is recorded as it happens rather than read
    /// back from [cancelled] afterwards, so a [resume] that lands before the action unwinds
    /// cannot turn a cancel into a timeout.
    std::atomic<Stop> stopped{Stop::none};
    /// Record why the running action was stopped, unless a reason is recorded already.
    void record_stop(Stop reason);
    /// [fetch_failures] when the running action was armed.
    uint32_t fetch_failures_at_arm = 0;
    /// Whether a fetch failed, other than with a 404 or 410, since the running action was armed.
    bool fetch_failed() const;
    /// Set by [cancel], cleared by [resume]. Read from the fetching thread.
    std::atomic<bool> owned_cancelled{false};
    /// Either &owned_cancelled or the caller's flag. Never null after construction.
    std::atomic<bool>* cancelled = &owned_cancelled;

    /// Arm the deadline for an action about to run, then run it.
    std::string with_deadline(const std::function<std::string()>& action);

    /// Start a new action: clear what the last one recorded and set the deadline.
    void arm_deadline();

    /// Throw [TimedOut] or [Cancelled] if the interrupt stopped the running action.
    void throw_if_stopped() const;

public:
    /**
     * @param cancel_flag  optional, and NOT owned. When given, [cancel] and [resume] set it
     *                     and the interrupt reads it, so a caller can stop a running action
     *                     without touching this object -- which matters because every other
     *                     method holds a lock for its duration, and an actor being freed
     *                     concurrently would otherwise leave cancel reading a dangling
     *                     pointer. It must outlive this actor.
     */
    ValhallaActor(const std::string& config_path,
                  ValhallaMobileHttpClient* http_client = nullptr,
                  std::atomic<bool>* cancel_flag = nullptr);

    /// The exact text [TimedOut] carries when the deadline elapsed.
    ///
    /// Fixed, and part of the contract: it is the only signal that survives the trip out to
    /// Swift and Kotlin, so a caller matches on it to tell "the origin is gone" from "this
    /// route does not exist".
    static constexpr const char* kTimedOutMessage = "valhalla-mobile: tile fetch deadline";

    /// The exact text [Cancelled] carries.
    static constexpr const char* kCancelledMessage = "valhalla-mobile: cancelled";
    /// The exact text of the error when a tile fetch failed, other than with a 404 or 410.
    static constexpr const char* kFetchFailedMessage = "valhalla-mobile: tile fetch failed";

    /// Raised when an action gave up because `mjolnir.tile_url_timeout` elapsed.
    ///
    /// A distinct type so a caller can tell "the origin is slow or gone" from "this route
    /// does not exist", which otherwise both surface as a generic failure.
    class TimedOut : public std::runtime_error {
    public:
        explicit TimedOut(const std::string& what) : std::runtime_error(what) {}
    };

    /// Raised when an action stopped because [cancel] was called.
    class Cancelled : public std::runtime_error {
    public:
        explicit Cancelled(const std::string& what) : std::runtime_error(what) {}
    };

    /**
     * Ask the action running now to stop, before its next tile fetch or within a few
     * thousand steps of its path search.
     *
     * A fetch already in flight finishes or hits its own timeout. Sticky until [resume]
     * clears it, because a cancel that raced ahead of the action it meant to stop would
     * otherwise be ignored.
     */
    void cancel();

    /// Clear a previous [cancel] so further actions can run.
    void resume();

    /**
     * Compute a route between the given locations. This is Valhalla's `route`
     * action.
     *
     * @param request  a `route` request as JSON. See
     *                 https://valhalla.github.io/valhalla/api/turn-by-turn/api-reference/
     * @return         the serialized response, in whichever format the request asked for
     */
    std::string route(const std::string& request);

    /**
     * Map-match a GPS trace onto the road network and return a route along the
     * matched path. This is Valhalla's `trace_route` action.
     *
     * @param request  a `trace_route` request as JSON. See
     *                 https://valhalla.github.io/valhalla/api/map-matching/api-reference/
     * @return         the serialized response, in whichever format the request asked for
     */
    std::string trace_route(const std::string& request);

    /**
     * Map-match a GPS trace onto the road network and return the attributes of
     * every edge along the matched path. This is Valhalla's `trace_attributes`
     * action.
     *
     * Unlike `trace_route`, this action always answers with Valhalla's own JSON —
     * the `format` option does not apply to it.
     *
     * @param request  a `trace_attributes` request as JSON. See
     *                 https://valhalla.github.io/valhalla/api/map-matching/api-reference/
     * @return         the serialized JSON response
     */
    std::string trace_attributes(const std::string& request);

    /**
     * Sample terrain heights under a shape. This is Valhalla's `height` action.
     *
     * @param request  a `height` request as JSON. See
     *                 https://valhalla.github.io/valhalla/api/elevation/api-reference/
     * @return         the serialized JSON response
     */
    std::string height(const std::string& request);

    /**
     * Compute a matrix of costs and times between every source and every target. This is
     * Valhalla's `sources_to_targets` action.
     *
     * @param request  a `sources_to_targets` request as JSON. See
     *                 https://valhalla.github.io/valhalla/api/matrix/api-reference/
     * @return         the serialized response, in whichever format the request asked for
     */
    std::string matrix(const std::string& request);
};

#endif // VALHALLAACTOR_H

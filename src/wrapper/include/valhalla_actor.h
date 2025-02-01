#ifndef VALHALLAACTOR_H
#define VALHALLAACTOR_H

#include <string>
#include <valhalla/tyr/actor.h>

class ValhallaActor {
private:
    valhalla::tyr::actor_t actor;
public:
    ValhallaActor(const std::string& config_path);
    
    std::string route(const std::string& request);
};

#endif // VALHALLAACTOR_H

#ifndef VALHALLAACTOR_H
#define VALHALLAACTOR_H

#include <string>
#include <valhalla/tyr/actor.h>

class ValhallaActor {
public:
    std::string route(const std::string& request, const std::string& config_path);
};

#endif // VALHALLAACTOR_H
#ifndef GENERATE_BINDINGS
#include <functional>
#include <string>
#include <utility>
#include <vector>
#endif

class capture_groups {
public:
    capture_groups();
    int size();
    const char* get_match(int index);
#ifndef GENERATE_BINDINGS
    bool search(std::string, std::regex);
private:
    std::smatch d_matches;
#endif
};

typedef void (*callback_function)(capture_groups*, void*);

typedef void (*default_callback)(const char*, void*);

#ifndef GENERATE_BINDINGS

using cb_func = std::function<void(capture_groups*, void*)>;
using default_func = std::function<void(const char*, void*)>;

using path_object = std::pair<std::string, cb_func>;
#endif

class uri_router {
public:
    uri_router();
    
    void register_path(const char* rgx_str, callback_function cb);
    void register_default(default_callback cb);
    bool match_path(const char* path, void* response);
    
#ifndef GENERATE_BINDINGS
    void register_path(std::string, cb_func);
    void register_default(default_func);
    bool match_path(std::string, void*);  
private:
    void default_default_cb(const char*, void*);
    
    std::vector<path_object> d_map;
    default_func d_default_handler;
     
#endif
};

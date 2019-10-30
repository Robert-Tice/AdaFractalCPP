#include <iostream>
#include <regex>

#include "uri_router.hh"

capture_groups::capture_groups() {}

int capture_groups::size() {
    return d_matches.size();
}

const char* capture_groups::get_match(int index) {
    if(index >= d_matches.size())
        return nullptr;

    return d_matches[index].str().c_str();
}

bool capture_groups::search(std::string path, std::regex rgx) {
    return std::regex_search(path, d_matches, rgx);
}

uri_router::uri_router() : d_default_handler(nullptr) { }

void uri_router::register_path(std::string rgx_str, cb_func cb) {
    d_map.push_back(std::make_pair(rgx_str, std::move(cb)));
}

void uri_router::register_path(const char* rgx_str, callback_function cb) {
    register_path(std::string(rgx_str), cb_func(cb));
}

void uri_router::register_default(default_func cb) {
    d_default_handler = cb;
}

void uri_router::register_default(default_callback cb) {
    register_default(default_func(cb));
}

bool uri_router::match_path(std::string path, void* response) {

    for(auto& i : d_map) {
        std::regex rgx(i.first);
        capture_groups cg;

        std::cout << "Matching " << path << " against " << i.first << std::endl;

        if(cg.search(path, rgx)) {
            std::cout << "Matched" << std::endl;

            if(cg.size() > 0) {
                i.second(&cg, response);
                return true;
            }
            else {
                i.second(nullptr, response);
                return true;
            }
        }
    }

    if(d_default_handler) {

        d_default_handler(path.c_str(), response);
        return true;
    }

    return false;
}

bool uri_router::match_path(const char* path, void* response) {
    return this->match_path(std::string(path), response);
}

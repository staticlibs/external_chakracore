/*
 * Copyright 2018, alex at staticlibs.net
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* 
 * File:   hello_chakra.cpp
 * Author: alex
 *
 * Created on May 12, 2018, 1:29 PM
 */

#include <iostream>
#include <string>

#include "ChakraCore.h"

int main() {
    JsRuntimeHandle runtime = JS_INVALID_RUNTIME_HANDLE;
    auto err_runtime = JsCreateRuntime(JsRuntimeAttributeNone, nullptr, std::addressof(runtime));
    if (JsNoError != err_runtime) {
        std::cout << "1" << std::endl;
        std::exit(1);
    }
    JsContextRef ctx = JS_INVALID_REFERENCE;
    auto err_ctx = JsCreateContext(runtime, std::addressof(ctx));
    if (JsNoError != err_ctx) {
        std::cout << "2" << std::endl;
        std::exit(1);
    }
    auto err_set = JsSetCurrentContext(ctx);
    if (JsNoError != err_set) {
        std::cout << "3" << std::endl;
        std::exit(1);
    }
    // auto script_str = std::string("'cafe\u0301'.normalize() + ' ' + 'caf\u00E9'.normalize()");
    auto script_str = std::string("42 + 1");
    JsValueRef script = JS_INVALID_REFERENCE;
    JsCreateString(script_str.c_str(), script_str.length(), std::addressof(script));
    auto url_str = std::string("test.js");
    JsValueRef url = JS_INVALID_REFERENCE;
    JsCreateString(url_str.c_str(), url_str.length(), std::addressof(url));
    JsValueRef result = JS_INVALID_REFERENCE;
    JsRun(script, 42, url, JsParseScriptAttributeNone, std::addressof(result));

    JsValueRef resultJSString;
    JsConvertValueToString(result, std::addressof(resultJSString));
    size_t len = 0;
    JsCopyString(resultJSString, nullptr, 0, std::addressof(len));
    auto res = std::string();
    res.resize(len);
    JsCopyString(resultJSString, std::addressof(res.front()), res.length(), nullptr);
    
    JsDisableRuntimeExecution(runtime);
    JsDisposeRuntime(runtime);

    if ("43" != res) {
        std::cerr << "Invalid script result: [" << res << "]" << std::endl;
        return 1;
    }

    return 0;
}


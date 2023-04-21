[![GitHub license](https://img.shields.io/github/license/Naereen/StrapDown.js.svg)](https://github.com/ahuca/TcBase/blob/main/LICENSE)

# TcBase - TwinCAT 3 base framework

## Introduction

This is an open-source TwinCAT 3 base framework providing a baseline for developing object-oriented TwinCAT 3 projects. It provides boilerplates of some well-known software design patterns, such as [state pattern](https://en.wikipedia.org/wiki/State_pattern), and [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern). More patterns to come. It aims to provide more advanced types of data collection, for now only a [list](https://github.com/ahuca/TcBase/blob/main/TcBase/TcBase/TcBase/Collection/FB_List.TcPOU). Additionally, it has some utilities like an [invocation tracker](https://github.com/ahuca/TcBase/tree/main/TcBase/TcBase/TcBase/Invocation%20Control) and [action](https://github.com/ahuca/TcBase/tree/main/TcBase/TcBase/TcBase/Action), which can be executed iteratively over an [I_Enumerable](https://github.com/ahuca/TcBase/blob/main/TcBase/TcBase/TcBase/Collection/I_Enumerable.TcIO), for example, `fbList.ForEach(fbRunAllCyclicTask)`.

This project is under heavy development, so there will not be any releases any time soon. However, the project is built to be a library, so you can manually produce a library out of this project from the source code. For instructions on how to do this, check [here](https://infosys.beckhoff.com/english.php?content=../content/1033/tc3_plc_intro/4189255051.html&id=).

## How to use the framework

To take full advantage of the framework - being an object-oriented framework itself - every new FB that you create should inherit from FB_Object or its children. Like how FB_State inherits from FB_Object and thus can be stored in FB_List without any extra implementation. At this point, you might be wondering "well that is a helluva lot of coupling", and we applaud such intuition. That is why we try our best to keep the framework as lite as possible, to minimize the coupling.

Being under heavy development, we advise you well to use [proxy](https://en.wikipedia.org/wiki/Proxy_pattern) - or simply put, a wrapper - when using this library, instead of direct usage.

## Dependencies

While [TcBase](https://github.com/ahuca/TcBase/tree/main/TcBase) doesn't require any 3rd-party dependencies, [TcBaseTest](https://github.com/ahuca/TcBase/tree/main/TcBaseTest) - housing all the unit tests for TcBase - does depend on [TcUnit](https://github.com/tcunit/TcUnit) version [1.2.0.0](https://github.com/tcunit/TcUnit/releases/tag/1.2.0.0).

## Acknowledgement

Some elements of the TcBase were based on parts of the open-sourced project [TcOpen](https://github.com/TcOpenGroup/TcOpen).

GlucoSuccess
================

GlucoSuccess is a unique iPhone application that utilizes [ResearchKit](https://github.com/ResearchKit/ResearchKit) and HealthKit to get a more accurate understanding of how various things affect the progression and management of type 2 diabetes. The app presents a variety of surveys and tasks to track health behaviors such as physical activity, diet and medications. 

Massachusetts General Hospital’s goals in this study are to understand how health behaviors influence blood glucose in real life, with a resolution greater than ever before. At the same time, the app provides personalized insights into how one’s daily diet and physical activity relate to their blood glucose values. 


Building the App
================

###Requirements

* Xcode 6.3
* iOS 8.3 SDK

###Getting the source

First, check out the source, including all the dependencies:

```
git clone --recurse-submodules git@github.com:ResearchKit/GlucoSuccess.git
```

###Building it

Open the project, `Diabetes.xcodeproj`, and build and run.


Other components
================

The shipping app also uses OpenSSL to add extra data protection, which
has not been included in the published version of the AppCore
project. See the [AppCore repository](https://github.com/researchkit/AppCore) for more details.

Data upload to [Bridge](http://sagebase.org/bridge/) has been disabled, the logos of the institutions have been removed, and the consent material has been marked as an example.

License
=======

The source in the GlucoSuccess repository is made available under the
following license unless another license is explicitly identified:

```
Copyright (c) 2015, Massachusetts General Hospital. All rights reserved. 

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1.  Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2.  Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of the copyright holder(s) nor the names of any contributors
may be used to endorse or promote products derived from this software without
specific prior written permission. No license is granted to the trademarks of
the copyright holders even if such marks are included in this software.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```


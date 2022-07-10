# red-frame  <sub><sup>_Website framework for redbean_<sup><sub>

### For what is _red-frame_
One of the coolest programs of the [Cosmopolitan] project is [Redbean].  
Redbean is a single-file distributable web server.  
It uses [Lua] for its dynamic serving language.  
Websites can be made with it by adding HTML files to the zip or serving directory.

[Lua]: https://www.lua.org/manual/5.4/ "Lua 5.4 manual"
[Cosmopolitan]: https://github.com/jart/cosmopolitan "Github repository"
[Redbean]: https://github.com/jart/cosmopolitan/blob/master/tool/net/redbean.c "redbean.c"

### What is red-frame
Red-frame is another website framework for redbean.  
With red-frame it is possible to define web-pages/applications.

### Why another website framework
It started as a personal learning project.  
And it ended as something useful.

The other frameworks are single-file and multipurpose.  
The aim of red-frame is not to be a single-file for every purpose.  
It is basic, tested and it can be extended to by other modules.

#### Other Redbean website frameworks
_Send a message if the following list is missing items._

* [Anpan](https://git.sr.ht/~shakna/anpan "shakna")
* [Fullmoon](https://github.com/pkulchenko/fullmoon "pkulchenko")


### Is red-frame replacing the `Route` function of Redbean?
No. red-frame is an extension.  
Even with red-frame added to the zip, requests can be made still for the files in the zip or the local directory.  
Therefor `Route` should be the fallback if the `Frame:RoutePath` function of red-frame fails.

### Documentation
Read the documentation here [:link: red-frame/doc](./doc/README.md "Documentation")

### Tests
Tests are created using [Probo](https://github.com/w13b3/Probo "Probo: Lua unit test framework").  
It is included in this project, but has another [license](https://github.com/w13b3/Probo/blob/main/LICENSE "License of Probo").  

#### How to run the tests
Add the content of this project to the Redbean file.  
Start the Redbean server.  
Open a browser and navigate to the `/test` path of the server.

The tests are passing on Redbean version 1.5
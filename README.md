lua_translate_tool

Description
-----------

lua script translate tool
    
Documentation
-------------

Build after install MinGW and third party library
 
    go get github.com/mattn/go-sqlite3
    
How to use:

Extract chinese character string
 
    ./trans getstring path
	
Use artificial translated documents(trans.txt), update to dictionary
 
    ./trans update chinese.txt trans.txt
	
Translate all file or folder(num is goroutine amount, default is 1)
 
    ./trans translate srcdir desdir [num]

License
-------------

The MIT License (MIT)

Copyright (c) 2016 liubo5

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

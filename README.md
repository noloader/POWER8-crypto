This is the Unoffical Guide to POWER8 in-core crypto. The document is a collection of field notes to help implementers cut-in POWER8 cryptography support. The notes are from our experience with implementing POWER8 for [AES-Instrinsics](https://github.com/noloader/AES-Intrinsics) and [SHA-Instrinsics](https://github.com/noloader/SHA-Intrinsics).

If you want to contribute to the book then clone the repository, make pull requests and open bug reports. Techinical editing is especially welcomed. We would be happy to take contributions and add additional authors.

If you only want the field notes then download power8-crypto.pdf. It is the compiled book with information that is missing from the IBM documents. If you find errors or omissions then make pull requests and open bug reports.

The book is built using DocBook. The instructions to setup DocBook on Ubuntu 16.04 and 18.04 with Apache FOP 2.4 are in docbook.pdf. Once DocBook is setup just run `make-book.sh` to create the book.

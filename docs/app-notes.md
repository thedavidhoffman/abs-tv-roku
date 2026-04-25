## On app load...

1. After a login, or if there is a logged in context, a call is made to the ABS API /loadLibraries. This will return an array such as { audiobooks, podcasts }, these are the top level/category of library types.
2. The result of the call to '/loadLibraries' is saved to an array of a reduced objects mapped to { id, name } which is stored in `m.session.libraries` in `MainScene`
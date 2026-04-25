# Audiobookshelf Notes

# Links

- https://www.audiobookshelf.org/
- https://github.com/advplyr/audiobookshelf
- https://deepwiki.com/audiobookshelf/audiobookshelf-api-docs/3-audiobookshelf-api-reference
- https://github.com/audiobookshelf/audiobookshelf-api-docs
- https://api.audiobookshelf.org/

# API
```
/login
    posted as form-data in body...
    {
        username: <username>
        password: <password>
    }
```

```
/libraries
    gets a list of all libraries... ie. { audiobooks, podcasts}
```

```
/libraries/<id>
    gets a specific library
```

```
/libraries/<id>/items?sort=media.metadata.title
    gets all items in a library
```

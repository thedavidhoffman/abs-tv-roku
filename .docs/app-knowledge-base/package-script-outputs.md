# Package Script Outputs

## Summary

`npm run package` can create two zip files when `npm run validate` allows
BrighterScript to package the app before the custom package script runs.

In this project:

- `out/abs-tv-roku.zip` is created by `npx bsc` during validation.
- `out/ABSTV.zip` is created by `scripts/package.mjs` through `roku-deploy`.

## Why It Happens

The `package` script runs:

```sh
npm run clean && npm run validate && node ./scripts/package.mjs
```

The `validate` script runs BrighterScript:

```sh
npx bsc --rootDir . --stagingFolder build/staging
```

BrighterScript defaults `--create-package` to `true`, so validation creates a
zip at `out/[root-folder-name].zip`. Because this repo folder is
`abs-tv-roku`, that output is:

```txt
out/abs-tv-roku.zip
```

Then `scripts/package.mjs` creates the intended release package:

```txt
out/ABSTV.zip
```

## Recommended Script Split

Validation should only compile and check the project. Packaging should be owned
by the package script.

Recommended `validate` script:

```json
"validate": "npx bsc --rootDir . --stagingFolder build/staging --create-package=false"
```

With that split:

- `npm run validate` checks the project without creating a zip.
- `npm run package` creates the release artifact, `out/ABSTV.zip`.
- `npm run deploy` can continue validating before deployment without leaving
  extra package artifacts behind.

## Tradeoff

Letting `validate` create a package proves that BrighterScript can complete the
zip step, but this is mostly redundant here because `npm run package` already
performs the real package creation with `scripts/package.mjs`.

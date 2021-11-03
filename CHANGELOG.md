Change Log
==========

### 2021-11-03

New:

- Lush now supports LushBuild, an extensible export framework.
- Lush now supports LushImport, an existing-colorscheme importer.
- Lush now supports user-providable compiler plugins.

Breaking:

- The compiler `exclude_keys` option has been removed in favour of the
  `vim_compatible` compiler plugin.

### 2021-06-28

New:

- Lush now supports HSLuv colorspace.
- Lush now supports mix() and readable() color operations.

### 2021-03-17

New:

- Lush now supports spec inheritance via extends({...}).with(...)
  or merge({...}).

### 2020-11-23

New:

- Lush.ify now reports errors in a more consistent format.
- Lush.ify now rate-limits eval attempts on parsing errors.

### 2020-11-21

New:

- Lush-spec now supports group inheritance.

### 2020-11-19

New:

- Lush now exists.

Made with Lush
==============

*You can use Lush with any theme on this page to adjust or extend them. See
[advanced
usage](https://github.com/rktjmp/lush.nvim#spec-extension-and-merging) in the
readme or `:h lush-extending-specs` for more details.*

*To add your theme to this list, see [Adding your theme to the
list](#adding-your-theme-to-the-list) at the bottom of this file.*

*Themes are sorted alphanumeric by theme name.*

Lush Community Themes
---------------------

### jellybeans-nvim

[metalelf0/jellybeans-nvim](https://github.com/metalelf0/jellybeans-nvim)

`require('lush_theme.jellybeans-nvim')`

A port of the jellybeans theme.

![first screenshot](metalelf0_jellybeans-nvim_1.png)

---
### onedark.nvim

[olimorris/onedark.nvim](https://github.com/olimorris/onedark.nvim)

`require('lush')(require('lush_theme.onedark_nvim'))`

My personal One Dark port for Neovim with Treesitter and LSP support, dark/light versions and lots of plugins.

![Dark](olimorris_onedark-nvim_dark.png)

![Light](olimorris_onedark-nvim_light.png)

---

Adding your theme to the list
-----------------------------

Submit a pull request with:

- [x] The theme details template filled out (see below)
- [x] At most 2 images (optional but recommended):
  - PNG format
  - Reasonable size (i.e. not a 4k res 30mb file)
  - Filenames follow the format:
    `<gh_username>_<gh_reponame_with_dots_as_underscores>_[1|2].png` and are in
    the `made_with_lush` directory (alongside this file)
- [x] Squash your commits with the message "`Add <theme name> to made_with_lush`"
  - ("`Update <theme_name> in made_with_lush`" if you are submitting a patch)

Details template:

```
### <theme_name>

[<gh_username/gh_reponame> or simliar service](https://github.com/user/repo)

`require(<what you require in your colours/vim file, probably 'lush_theme.theme_name'>)`

<(optional) max 50ish (be reasonable) word description of theme or features (plugins, terminal themes, etc).>

![](gh_username_gh_reponame_with_dots_as_underscores_1.png)

![](gh_username_gh_reponame_with_dots_as_underscores_2.png)

---
```

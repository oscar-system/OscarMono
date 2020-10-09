# OSCAR mono repo TODO

## Advantages and disadvantages of switching to a mono repo

- TODO: describe what a monorepo is

- Modularity is nice if one has well-defined modules and clear interfaces
- But currently we do not have that (which is why all our packages are 0.x releases)
- By having things in a dozen different repositories, certain changes become very difficult and
  time consuming; this wastes a lot of time and energy, or leads to useful changes not being made
  at all
- makes it harder to move functionality between packages, so people waste time deciding where to
  put a feature before even implementing it; with a mono
- it can also be difficult to find out where something is; or tmo


- TODO: which repos / packages should be in there?

## Workflow

- TODO: discuss workflow
- TODO: e.g. perhaps need a script to dev all packages?
- TODO: mention possibility of leaving certain packages 
- TODO: how to test the JLLs? See also the CI section, this is closely related
   - perhaps we can add some helper scripts to make this easier?


## Compatibility concerns

- multiple Julia packages in a single repo is new in Julia 1.5
- but the resulting packages, once releases, can also be used in older Julia versions
- so devs need Julia 1.5 or newer, but users don't
- anyway, Julia 1.6 will be the next LTS release of Juli and we want to switch to that as
  minimal Julia version ASAP anyway



## Setting up the CI

For PRs:
  - using GitHub Actions and/or Travis CI
  - naive approach: always build and test all packages
  - but that's too slow
  - instead determine which subdirs were touched by a PR
  - run tests for all "touched" packages (this restores the "status quo")
  - but also run tests for all packages "higher up", i.e. those depending on the changed packages
  - aggressively cache build artifacts, so that e.g. JLLs don't need to be rebuilt

For Jenkins
  - TODO

Testing JLL changes:
  - adding new feature to `Singular.jl` often requires updating `libsingular-julia` / `libsingular_julia_jll`
    in lockstep, and possibly also `Singular_jll.jl`
  - likewise for Polymake
  - right now our CI does not support this at all
  - but now we can!
  - key for this is figuring out how to test build a JLL and inject that copy into the Julia package system
    - TODO describe how to do this
  - for performance reasons, we should cache the resulting build artifacts (at least for the `master` branch)
  - TODO: what about `Singular_jll`, `Flint_jll`, `lib4ti2_jll`


## Package releases

- TODO: research status of tooling
- TODO: describe how to make releases of a single package vs. multiple select packages vs. "releasing all"



## Misc stuff

- archive the old repos?
- could migrate existing issues to new repos (at least for repos in the oscar-system organization)
- use `git subtree` to allow repositories to 





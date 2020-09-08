Problem:  
  Polymake needs flint needs gmp
  Nemo needs antic needs flint needs gmp

Depending on the order of the calls to __init__ two copies of libflint (and libgmp) are loaded.
The ones coming from Nemo have the memory allocators set to use the julia allocators, while
Polymake does not.

Later in the code
  I call libantic
    which calls libflint to alloc memory
  Then I call libflint to free the memory, as antic is a derivative of flint.

  Now antic calls the 2nd copy of libflint, the one where memory management is done by
  the system

  Thus the free from the 1st call to libflint crashes.

Alternative approach
  set all memory functions in all gmp's to match julia:
    fails as allocations in polymake are happening before Julia can change this.


Thus LoadFlint

which will only make sure that libgmp and libflint are in the process space and properly initialized.

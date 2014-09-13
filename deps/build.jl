oldpwd = chomp(readall(`pwd`))

pkgdir = Pkg.dir("Nemo") 
pwd = "$pkgdir/src"

cd(pwd)

on_windows = @windows ? true : false

if on_windows
   oldpth = ENV["PATH"]
   pth = split(oldpth, ";")
   shift!(pth)
   shift!(pth)
   pth = join(pth)

   if Int == Int32
      ENV["MSYSTEM"]="MINGW32"
   else
      ENV["MSYSTEM"]="MINGW64"
   end
end

# install MPIR

run(`wget http://mpir.org/mpir-2.7.0-alpha10.tar.bz2`)
run(`tar -xvf mpir-2.7.0-alpha10.tar.bz2`)
run(`rm mpir-2.7.0-alpha10.tar.bz2`)
cd("$pwd/mpir-2.7.0")

if on_windows
   # run(`sed -i 's/data.rel.ro.local,"aw",@progbits/data.rel.ro.local,"aw"/g' $pwd/mpir-2.7.0/mpn/x86_64/x86_64-defs.m4`)
   ENV["PATH"] = pth
   if Int == Int32
      run(`sh configure --prefix=$pwd --enable-gmpcompat --disable-static --enable-shared ABI=32`)
   else
      run(`sh configure --prefix=$pwd --enable-gmpcompat --disable-static --enable-shared ABI=64`)
   end
   run(`sh -c make -j`)
   run(`sh -c make install`)
   ENV["PATH"] = oldpth
else
   run(`./configure --prefix=$pwd --enable-gmpcompat --disable-static --enable-shared`)
   run(`make -j4`)
   run(`make install`)
end

cd(pwd)

# install MPFR

run(`wget http://www.mpfr.org/mpfr-current/mpfr-3.1.2.tar.bz2`)
run(`tar -xvf mpfr-3.1.2.tar.bz2`)
run(`rm mpfr-3.1.2.tar.bz2`)
cd("$pwd/mpfr-3.1.2")

if on_windows
   ENV["PATH"] = pth
   run(`sh configure --prefix=$pwd --with-gmp=$pwd --disable-static --enable-shared`)
   run(`sh -c make -j`)
   run(`sh -c make install`)
   ENV["PATH"] = oldpth
else
   run(`./configure --prefix=$pwd --with-gmp=$pwd --disable-static --enable-shared`)
   run(`make -j4`)
   run(`make install`)
end

cd(pwd)

# install FLINT

run(`git clone https://github.com/wbhart/flint2.git`)
cd("$pwd/flint2")

if on_windows
   ENV["PATH"] = pth
   if Int == Int32
      run(`sh configure --prefix=$pwd --disable-static --enable-shared --with-mpir=$pwd --with-mpfr=$pwd ABI=32`)
   else
      run(`sh configure --prefix=$pwd --disable-static --enable-shared --with-mpir=$pwd --with-mpfr=$pwd ABI=64`)
   end
   run(`sh -c make -j`)
   run(`sh -c make install`)
   ENV["PATH"] = oldpth
else
   run(`./configure --prefix=$pwd --disable-static --enable-shared --with-mpir=$pwd --with-mpfr=$pwd`)
   run(`make -j4`)
   run(`make install`)
end

cd(pwd)

if on_windows
   push!(DL_LOAD_PATH, "$pkgdir\\src\\lib")
else
   push!(DL_LOAD_PATH, "$pkgdir/src/lib")
end

cd(oldpwd)


#= function res_Delete(r::resolvente, length::Cint, R::ring)
    r_ptr = reinterpret(Ptr{Nothing},r)
    return res_Delete_helper(r_ptr,length,R)
end

function res_Copy(r::resolvente, length::Cint, R::ring)
   icxx"""resolvente res = (resolvente) omAlloc0(($length + 1)*sizeof(ideal));
          rChangeCurrRing($R);
          for (int i = $length - 1; i >= 0; i--)
          {
             if ($r[i] != NULL)
                res[i] = id_Copy($r[i], $R);
          }
          res;
       """
end

function getindex(r::resolvente, i::Cint)
   icxx"""(ideal) $r[$i];"""
end

function syMinimize(r::resolvente, length::Cint, R::ring)
   icxx"""const ring origin = currRing;
          syStrategy temp = (syStrategy) omAlloc0(sizeof(ssyStrategy));
          resolvente result;
          rChangeCurrRing($R);
          temp->fullres = (resolvente) omAlloc0(($length + 1)*sizeof(ideal));
          for (int i = $length - 1; i >= 0; i--)
          {
             if ($r[i] != NULL)
                temp->fullres[i] = idCopy($r[i]);
          }
          temp->length = $length;
          syMinimize(temp);
          result = temp->minres;
          temp->minres = NULL;
          /* syMinimize increments this as it returns a value we ignore */
          temp->references--;
          syKillComputation(temp, $R);
          rChangeCurrRing(origin);
          result;
       """
end

function syBetti(res::resolvente, length::Cint, R::ring)
   iv = icxx"""const ring origin = currRing;
         rChangeCurrRing($R);
         int dummy;
         intvec *iv = syBetti($res, $length, &dummy, NULL, FALSE, NULL);
         rChangeCurrRing(origin);
         return iv;
      """
   nrows = icxx"""$iv->rows();"""
   ncols = icxx"""$iv->cols();"""
   betti = icxx"""int *betti = (int *)malloc($ncols*$nrows*sizeof(int));
         for (int i = 0; i < $ncols; i++) {
            for (int j = 0; j < $nrows; j++) {
               betti[i*$nrows+j] = IMATELEM(*$iv, j+1, i+1);
            }
         }
         delete($iv);
         return &betti[0];
      """
   unsafe_wrap(Array, betti, (nrows, ncols); own=true)
end
 =#

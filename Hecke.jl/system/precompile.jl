quadratic_field(10)
k, a = cyclotomic_field(11)
automorphism_group(k)
kt, t = k["t"]
factor(t^2-a)
factor(t^5-a)
k, a = wildanger_field(3, 13)
h = hilbert_class_field(k)
K = number_field(h)
L = simple_extension(K)[1]
absolute_field(L)
discriminant(maximal_order(K))
norm_equation(k, 27)

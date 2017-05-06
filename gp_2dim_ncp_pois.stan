functions {
  matrix gp_exp_quad_chol(real[] x, real alpha, real len, real jitter) {
    int dim_x = size(x);
    matrix[dim_x, dim_x] L_K_x;
    matrix[dim_x, dim_x] K_x = cov_exp_quad(x, alpha, len);
    for (n in 1:dim_x)
      K_x[n,n] = K_x[n,n] + jitter;
    L_K_x = cholesky_decompose(K_x);
    return L_K_x;
  }
}
data {
  // Model is for outcomes that have been
  // observed on a 2 dimensional grid
  int<lower=1> dim_I; // size of grid dimension 1
  int<lower=1> dim_J; // size of grid dimension 2
  int y[dim_J,dim_I]; // Outcome
  real I[dim_I]; // locations - 1st dimension
  real J[dim_J]; // locations - 2nd dimension
}
parameters {
  real<lower=0> len_scale_I; // length-scale - 1st dimension
  real<lower=0> len_scale_J; // length-scale - 2nd dimension
  real<lower=0> alpha; // Scale of outcomes
  // Standardized latent GP
  matrix[dim_I, dim_J] y_tilde;
}
model {
  matrix[dim_I, dim_J] latent_gp; 
  {
    matrix[dim_I, dim_I] L_K_I = gp_exp_quad_chol(I, 1.0, len_scale_I, 1e-12);
    matrix[dim_J, dim_J] L_K_J = gp_exp_quad_chol(J, alpha, len_scale_J, 1e-12);

    // latent_gp is matrix-normal with among-column covariance K_I
    // among-row covariance K_J
    
    latent_gp = L_K_I * y_tilde * L_K_J';
  }
  // priors
  len_scale_I ~ gamma(8, 2);
  len_scale_J ~ gamma(8, 2);
  alpha ~ normal(0, 1);
  to_vector(y_tilde) ~ normal(0, 1);
  
  // likelihood
  to_array_1d(y) ~ poisson_log(to_vector(latent_gp));
}

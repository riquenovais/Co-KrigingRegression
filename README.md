# Co-Kriging Regression Implementation

This repository contains an implementation of the **Co-Kriging regression method**, which objective is to showcase how multi-fidelity modeling can improve prediction accuracy compared to standard Kriging.

---

### Overview
> [!NOTE]
> The framework combines high-fidelity (expensive) and low-fidelity (cheap) data within a multi-fidelity Gaussian process formulation. Initially, a fixed random seed is defined to ensure reproducibility. Two datasets are generated: the expensive dataset represents evaluations from a complex target function, while the cheap dataset corresponds to a simplified and less accurate approximation of the same function. For baseline comparison, a classical Kriging metamodel is constructed using the UQLab interface, where the expensive samples are used to train a Gaussian process over a uniformly defined input domain. A separate validation set is generated for performance assessment. The co-Kriging model is modeled as a scaled version of the cheap response plus a discrepancy Gaussian process. Hyperparameters are estimated through likelihood maximization using dedicated likelihood functions for both the cheap and difference processes. Finally, the script produces comparative plots showing expensive and cheap observations, Kriging predictions, co-Kriging predictions, and corresponding confidence intervals. These results illustrate how multi-fidelity modeling can enhance prediction accuracy when correlated low-fidelity information is available.

> ℹ️ **Note**  
> This code requires the <a href="https://www.uqlab.com/" target="_blank">UQLab</a> framework to run.
> <br><br>
> <a href="https://www.uqlab.com/" target="_blank" style="text-decoration: none;">
>   <img src="uqlab_logo.svg" width="120" alt="UQLab Logo">
> </a>

### Authors
- Henrique Cordeiro Novais (FEIS/UNESP)
- Samuel da Silva (FEIS/UNESP)


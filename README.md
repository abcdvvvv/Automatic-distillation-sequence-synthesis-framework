# Automatic distillation sequence synthesis framework

[![Zenodo DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14717642.svg)](https://doi.org/10.5281/zenodo.14717642)
[![Article DOI](https://img.shields.io/badge/Article%20DOI-10.1016%2Fj.compchemeng.2023.108549-red)](https://doi.org/10.1016/j.compchemeng.2023.108549)

This is a MATLAB implementation of the distillation sequence synthesis methodology presented in the paper "*An automatic distillation sequence synthesis framework based on a preorder traversal algorithm.*" Refer to the aforementioned paper for theoretical aspects. This README.md will outline the guidelines for utilizing the framework.

<img src="https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework/blob/master/images/github8-31.png" width="760">

> [!NOTE]
> **Long-Term Maintenance Notice**
>
> This package is now in long-term maintenance mode. Going forward, there will be no new features or functionality added. Our focus will be solely on:
>
> - **Stability and Security:** Providing critical bug fixes and security patches as necessary.
> - **Documentation:** Keeping the documentation updated to accurately reflect the current state of the package.
> - **Critical Issues:** Addressing critical issues that affect functionality or security.
>
> Please note that while community contributions are appreciated, new feature requests may not be prioritized. Thank you for your understanding and continued support.

## Requirements

Aspen Plus: V11 or above

MATLAB: 2022a or above

MATLAB Optimization Toolbox™

## User Guide (run from the GUI)

The program is relatively simple to run from the GUI. To achieve this, please adhere to the following steps.

1. Open Basic Settings and select the .bkp file you need. Use the "UnitSetSIPlus.bkp" file from the source code or installation package to add the "SI+" unit set to your simulation file.
<img src="https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework/blob/master/images/GUI1.png" width="400">

2. Enter the name of the stream to be analyzed. This is usually the name of the stream entering the separation section.

3. Select the maximum number of solutions and the temporary file storage path (```work_dir```).

4. Open the Component spec. tab and define component names based on the selected simulation file. Note that the component name and the simulation file must correspond one-to-one. Define the product set where 0 is not a product, 1 is a product, and 2 is a mixture product.
<img src="https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework/blob/master/images/GUI2.png" width="400">

5. (optional) You can specify recovery and column pressure for two key components.

TODO: I will add about the usage of the extractive distillation function in the future.

## User Guide (Scripting Interface)

Use the following steps to quickly set up and run the framework in your MATLAB environment:

1. Download the complete code package and unzip it to your preferred location.

2. Copy the file `src/main_template.m` and open it in MATLAB. Ensure that MATLAB’s current folder is set to the **parent directory** of `src` (the program root).

3. **Prepare the Aspen Plus file**  
   1. Create an Aspen Plus `.bkp` file and place it in the `/simulation file/baseFile` directory.  
   2. In `main_template.m`, assign the name of this file to the variable `basefile`.

4. **Define components and boiling points**  
   1. Within the `.bkp` file, define the required components. Their names must not exceed five characters.  
   2. Determine the boiling points of all substances and list them in the structure `material.name` in ascending order of boiling point.

5. Add a feed stream in the Aspen Plus flowchart, and specify its name in the variable `feedstream` within `main_template.m`.

6. In Aspen Plus, choose the SI units for consistent parameter settings.

7. Configure any remaining parameters as indicated in `main_template.m`, then run the script to execute the framework.

8. For additional configuration options or more detailed explanations, consult the descriptions in each individual script.

## src/main_template.m

This script contains the parameters, see the comments in the script.

```
basefile = 'case3.bkp';

feedstream = 'R1-1'; % The stream name entering the separation section

% material: A structure that contains the name of components and specified products.
material = struct( ...
    'name',{'NC3','IC4','NC4','IC5','NC5','CC5','IC61','IC62','IC63','NC6','CC61', ...
    'IC7','C6H6','CC62','NC7'}, ...
    'product',{0,0,0,1,1,1,1,0,0,0,0,0,0,0,0});

% gen_rule: A structure that specifies the recovery and pressures between component pairs.
gen_rule{1} = struct( ...
    'name1',{"default","IC4"}, ...
    'name2',{"default","IC5"}, ...
    'P',{1.5*1e5,5.3*1e5}, ... % unit: Pa
    'recovl',{0.999,[]}, ...
    'recovh',{0.001,[]});

% exheatflow: Heat exchangers other than distillation columns in case of heat integration.
exheatflow = [];

% How many optimal solutions to generate
max_solution = 5;

% Corresponds to the price defined in the `src/get_utility_price.m`
utility_set = 1;

% colpressure is used to control whether the column pressure is optimized (1) or not (0). If optimizing, ensure property analysis has been added as indicated below.
colpressure = 1;

% Automatic addition of physical property analysis
addPS = 1;
unit = 'SI';

% *regression* = 1 was used to calculate the relationship between feed flow F and CAPEX using linear regression. No regression when it equals 0.
% 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
regression = 0;

% *heat_integration* indicates whether the heat integration calculation is performed (1) or not (0).
heat_integration = 0;

% pops up a graph after running, which shows the sensitivity analysis of the heating utility to the optimal solution.
sensitivity_ana = 0;

% *work_dir* allows you to set your own working directory. The program will create files in that directory.
% The default directory is the "simulation file" folder in the current folder.
work_dir = fullfile('D:','distillation',filesep); 

AF = 1/3; % Annualization factor of the capital cost, which spreads the fixed capital investment of a chemical plant over each year, taking into account the time value of money.

% seq = get_force_selection(max_solution); % Certain sequences can be forcibly selected

run src\main_program.m  
```

`max_solution` controls how many optimal solutions the program solves for. The limitation of not being able to solve for more than four sequences has been fixed since version 1.1. You can now solve up to the maximum number of feasible sequences. Try to calculate the maximum number of sharp separation sequences with this formula! $[2(n_{\mathrm{c}}-1)]!/n_{\mathrm{c}}!(n_{\mathrm{c}}-1)!$

`addPS` determines whether a physical property analysis is automatically added. We recommend turning it on. To do this, you need to manually import the provided "UnitSetSIPlus.bkp" file in the unit set of Aspen Plus. This file contains the unit set "SI+" for the internal calculations of the program.

### The structure `material` and `gen_rule`           

Those structures are used to define the components or groups to be separated. Please refer to sample 'case3.bkp' for the format. Non-products are defined as 0, pure substance products are defined as 1, and mixture products are defined as 2.

Here is an example. It defines four components: n-propane, n-butane, isopentane, and n-pentane. N-propane is defined as a non-product, n-butane is defined as a product, and isopentane and n-pentane are defined as a "group".
```
material = struct( ...
    'name',{'NC3','NC4','IC5','NC5'}, ...
    'product',{0 1 2 2});  
```
You can specify the default pressure and the default recovery rate with the structure `gen_rule{1}`. You can also specify the recovery rate for a substance.

The following example shows how to set the default pressure to 1 bar with a recovery rate of 0.999/0.001, but specify a pressure of 2 bar and a recovery rate of 0.98/0.02 for NC4 and IC5.
```
gen_rule{1} = struct( ...
    'name1',    {"default" "NC4"}, ...
    'name2',    {"default" "IC5"}, ...
    'P',        {1          2}, ...     
    'recovl',   {0.999      0.98}, ...
    'recovh',   {0.001      0.02});  
```

If you want to use more than one set of utilities, specify the set of utilities in this file, e.g. `utility_set=2;` then define them in 'script/set_utility_price.m'. 

*exheatflow* is a variable that can append an external heat exchanger, or delete the contents of this structure if there is no external heat exchanger. For example `'Ti',{},...`
```
exheatflow = struct( ... % Heat integration for adding external heat flow
    'Ti',{30,300}, ... % input temperature
    'To',{35,200}, ... % output temperature
    'Q', {2000,-1000});% duty
```

## script/main_program.m

This script creates a distillation sequence superstructure using the preorder traversal algorithm and the DSTWU model. The program will try to execute the simulation. 
If the simulation proceeds without errors, this script will adjust the parameters and then use the simulation results to formulate the MILP problem. Note that all separations are sharp separations.

## src/main2.m

This script redeploys the optimal distillation sequence using the Radfrac model and optimizes it using an improved quadratic interpolation algorithm.

main2.m and main.m are separate, but main2.m needs to use the workspace variables generated by main.m. One way is to run main2.m without closing MATLAB after running main.m. Another way is to run main2.m by loading the .mat file that was generated the last time you ran main.m. For the second way, you can load the file manually (e.g., case1.mat) before running main2.m.

The user can choose which distillation sequences to redeploy by changing the loop range in `for d=1:1`. (For example, `d=2:2` deploys only the second-best solution, and `d=1:3` deploys the top three)

## Output

All the results of the calculations are stored in a spreadsheet called **output.xlsx**. In version 1.1, the format of the spreadsheet was optimized to make it more suitable for use in publications.

If you successfully run through main.m, you will get all the data in the list, including solution1(2,3) and TAC. You will get the capital cost data for the Radfrac columns only if you run through main2.m.

If you have any problems using the framework, please leave a comment on the GitHub issues page or email abcdvvvv@gmail.com

## License

This software is open source under the GNU General Public License v3.0.

## Citation Guidelines

Thank you for your interest in our work! This repository contains both the **research methodology** described in our paper and the **software implementation** that realizes it. To ensure proper acknowledgment and reproducibility, please use the appropriate citation(s) as follows:

### 1. If you use our methodology or build upon the approach described in the paper

Please cite our **paper**:

[![Article DOI](https://img.shields.io/badge/Article%20DOI-10.1016%2Fj.compchemeng.2023.108549-red)](https://doi.org/10.1016/j.compchemeng.2023.108549)

### 2. If you use the software (source code, binaries, or scripts)

Please cite our **software**:

[![Zenodo DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14717642.svg)](https://doi.org/10.5281/zenodo.14717642)

<details>
<summary>Click to view the recommended software citation in BibTeX</summary>

```bibtex
@software{karei_2025_14717642,
  author       = {karei},
  title        = {abcdvvvv/Automatic-distillation-sequence-
                   synthesis-framework: v1.2.0-alpha
                  },
  month        = jan,
  year         = 2025,
  publisher    = {Zenodo},
  version      = {v1.2.0-alpha},
  doi          = {10.5281/zenodo.14717642},
  url          = {https://doi.org/10.5281/zenodo.14717642},
}
```
</details>

### 3. If you rely on both the paper and the software

We appreciate that you might be referencing the concepts from our paper **and** making direct use of this repository. In that case, **please cite both** to acknowledge our methodological and software contributions. This helps give credit for the theoretical foundation and the practical implementation alike.

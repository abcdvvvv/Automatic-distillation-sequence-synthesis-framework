# Automatic distillation sequence synthesis framework

This is a MATLAB implementation of the distillation sequence synthesis methodology presented in the paper "*An automatic distillation sequence synthesis framework based on a preorder traversal algorithm.*" Refer to the aforementioned paper for theoretical aspects. This section will outline the guidelines for utilizing the framework.

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
<img src="https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework/blob/master/images/GUI1.png" width="360">

2. Enter the name of the stream to be analyzed. This is usually the name of the stream entering the separation section.

3. Select the maximum number of solutions and the temporary file storage path (```work_dir```).

4. Open the Component spec. tab and define component names based on the selected simulation file. Note that the component name and the simulation file must correspond one-to-one. Define the product set where 0 is not a product, 1 is a product, and 2 is a mixture product.
<img src="https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework/blob/master/images/GUI2.png" width="360">

5. (optional) You can specify recovery and column pressure for two key components.

TODO: I will add about the usage of the extractive distillation function in the future.

## User Guide (run from the scripting interface)

The following steps will guide you through the quick setup of the framework's runtime environment.

1. Begin by downloading and unzipping the complete code package.
2. Create a new Aspen Plus simulation file. Define components according to preferences or use provided case files. Add a feed stream in the flowchart and input its name into the variable 'feedstream' in 'main.m' for integration.
3. In Aspen Plus, establish a 'PS-1' property set item to analyze mixture vaporization heat (DHVLMX) in kJ/kmol.
4. Put the mentioned file in '/simulation file/baseFile' directory. Input its name into the variable 'basefile' in 'main.m'.
5. Modify 'name2struct.m' by adding a case for the new file's name. Create a 'material' structure as outlined in the 'name2struct.m' section for defining the product subset.
6. Execute the 'main.m' script. :tada:

For additional configuration customization, refer to the detailed descriptions of each individual script.

### main.m

This script creates a distillation sequence superstructure using the preorder traversal algorithm and the DSTWU model. The program will try to execute the simulation. If the simulation proceeds without errors, this script will adjust the parameters and then use the simulation results to formulate the MILP problem. Note that all separations are sharp separations.

There are eight user-specified parameters in this function
```
basefile = 'case3.bkp';
feedstream = 'R1-1';    % The stream name entering the separation section
max_solution = 1;       % How many optimal solutions to generate
regression = 0;         % 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
heat_integration = 0;   % Heat integration
sensitivity_ana = 0;     % whether to perform sensitivity analysis
work_dir = fullfile(pwd,'Simulation file',filesep); % Setting up the working directory
AF = 1/3;               % Annualization factor
```
*regression* = 1 was used to calculate the relationship between feed flow F and CAPEX using linear regression. No regression when it equals 0.

*heat_integration* indicates whether the heat integration calculation is performed (1) or not (0). The code for heat integration is not yet complete and in some cases it is not possible to derive feasible solutions. To be fixed.

*work_dir* allows you to set your own working directory. The program will create files in that directory. The default directory is the "simulation file" folder in the current folder. It is also acceptable to use an array of strings to represent the directory, for example `work_dir='d:/distillation/'`. Remember to add the slash at the end.

*AF* is an annualized factor of the capital cost, which spreads the fixed capital investment of a chemical plant over each year, taking into account the time value of money.

If you want to turn on automatic column pressure adjustment, you must set up an additional physical property analysis in Aspen, they are

- Critical temperature of the mixture (TCMX) in °C. Set this item in PS-2.
- Bubble point pressure and dew point pressure (PBUB and PDEW) in bar. Set up these two items in PS-3. On the Qualifiers tab, uncheck System Temperature. On the right hand side enter the minimum temperature at which cooling water will be used, e.g. 40°C.

This script pops up a graph after running, which shows the sensitivity analysis of the heating utility to the optimal solution.

Project Address: [Links to this page](https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework)

### name2struct.m

Use this file to define the components or groups to be separated. Please refer to sample case3.bkp for the format. Non-products are defined as 0, pure substance products are defined as 1, and mixture products are defined as 2.

Here is a simple example. It defines four components: n-propane, n-butane, isopentane, and n-pentane. N-propane is defined as a non-product, n-butane is defined as a product, and isopentane and n-pentane are defined as a "group".
```
case 'case1.bkp'
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
If you want to use more than one set of utilities, specify the set of utilities in this file, e.g. `utility_set=2;` then define them in utilities.m. 

```
    exheatflow = struct( ... % Heat integration for adding external heat flow
        'Ti',{30,300}, ... % input temperature
        'To',{35,200}, ... % output temperature
        'Q', {2000,-1000});% duty
    max_solution = 3; % How many optimal solutions to generate
    utility_set = 1;
    colpressure = 0; % whether to optimize column pressure
    addPS = 1; % Automatic addition of property analysis
    unit = 'SI+';
```
*exheatflow* is a variable that can append an external heat exchanger, or delete the contents of this structure if there is no external heat exchanger. For example `'Ti',{},...`

*max_solution* controls how many optimal solutions the program solves for. The limitation of not being able to solve for more than four sequences has been fixed since version 1.1. You can now solve up to the maximum number of feasible sequences. Try to calculate the maximum number of sharp separation sequences with this formula! $[2(n_{\mathrm{c}}-1)]!/n_{\mathrm{c}}!(n_{\mathrm{c}}-1)!$

*colpressure* is used to control whether the column pressure is optimized (1) or not (0). If optimizing, ensure property analysis has been added as indicated below.

*addPS* determines whether a physical property analysis is automatically added. We recommend turning it on. To do this, you need to manually import the provided "UnitSetSIPlus.bkp" file in the unit set of Aspen Plus. This file contains the unit set "SI+" for the internal calculations of the program.

### main2.m

This script redeploys the optimal distillation sequence using the Radfrac model and optimizes it using an improved quadratic interpolation algorithm.

main2.m and main.m are separate, but main2.m needs to use the workspace variables generated by main.m. One way is to run main2.m without closing MATLAB after running main.m. Another way is to run main2.m by loading the .mat file that was generated the last time you ran main.m. For the second way, you can load the file manually (e.g., case1.mat) before running main2.m.

The user can choose which distillation sequences to redeploy by changing the loop range in `for d=1:1`. (For example, `d=2:2` deploys only the second-best solution, and `d=1:3` deploys the top three)

### Output

All the results of the calculations are stored in a spreadsheet called **output.xlsx**. In version 1.1, the format of the spreadsheet was optimized to make it more suitable for use in publications.

If you successfully run through main.m, you will get all the data in the list, including solution1(2,3) and TAC. You will get the capital cost data for the Radfrac columns only if you run through main2.m.

If you have any problems using the framework, please leave a comment on the GitHub issues page or email abcdvvvv@gmail.com

## License

This software is open source under the GNU General Public License v3.0.

If this tool helps you, please consider citing our paper. Thank you!

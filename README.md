# Automatic distillation sequence synthesis framework

This is a framework for automated distillation sequence synthesis using Aspen Plus and MATLAB.

![image](https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework/blob/master/images/github2.png)

This program is for development use only and does not have any graphical user interface. The user should have at least a basic knowledge of MATLAB programming and a background in chemical engineering.

## Requirements

Aspen Plus: V11 or higher

MATLAB: 2022a or above

MATLAB Optimization Toolbox™

## User Guide

The user needs to download the entire code package to run the program.

1. Prepare a simulation file. The user needs to define the components needed first. Then draw a feed stream in the flowchart screen and enter the name of that stream in main.m (feedstream).
2. Create a new item in the property set of Aspen Plus, named PS-1, to analyze the mixture's vaporization heat (DHVLMX) in kJ/kmol.
3. Place this file in /simulation file/baseFile and enter the name of the file into main.m (basefile).

### main.m

This function creates a distillation sequence superstructure using the preorder traversal algorithm and the DSTWU model. The program will try to execute the simulation. If the simulation is error-free, it will adjust the parameters and then use the simulation results to formulate the MILP problem. Note that all separations are sharp separations.

There are **six** user-specified parameters in this function

```
basefile = 'case3.bkp';
feedstream = 'R1-1';    % The stream name entering the separation section
max_solution = 1;       % How many optimal solutions to generate
regression = 0;         % 1:regress CAPEX on F; 0:Calculate only CAPEX(y), independent of F
heat_integration = 0;   % Heat integration
exheatflow = struct( ...% Heat integration for adding external heat flow
    'Ti',{30,300}, ...  % input temperature
    'To',{35,200}, ...  % output temperature
    'Q', {2000,-1000}); % duty
col_optim = 0;          % Whether or not to perform column optimization
work_dir = fullfile('D:','distillation',filesep); % Setting up the working directory
```
If you want to turn on automatic column pressure adjustment, you must set up an additional physical property analysis in Aspen.

[Links to this page](https://github.com/abcdvvvv/Automatic-distillation-sequence-synthesis-framework)

### name2struct.m

Use this file to define the components or groups to be separated. Please refer to sample case3.bkp for the format. Non-products are defined as 0, pure substance products are defined as 1, and mixture products are defined as 2.

You can specify the default pressure and the default recovery rate with the structure `gen_rule{1}`. You can also specify the recovery rate for a substance.

If you want to use more than one set of utilities, specify the set of utilities in this file, e.g. `utility_set=2;` then define them in utilities.m. 

### main2.m

We are working on the remaining guides...

## Practice: Customize your first GitHub website by writing HTML code

Want to edit the site you just published? Let’s practice commits by introducing yourself in your `index.html` file. Don’t worry about getting it right the first time—you can always build on your introduction later.

Let’s start with this template:

```
<p>Hello World! I’m [username]. This is my website!</p>
```

To add your introduction, copy our template and click the edit pencil icon at the top right hand corner of the `index.html` file.

<img width="997" alt="edit-this-file" src="https://user-images.githubusercontent.com/18093541/63131820-0794d880-bf8d-11e9-8b3d-c096355e9389.png">


Delete this placeholder line:

```
<p>Welcome to your first GitHub Pages website!</p>
```

Then, paste the template to line 15 and fill in the blanks.

<img width="1032" alt="edit-githuboctocat-index" src="https://user-images.githubusercontent.com/18093541/63132339-c3a2d300-bf8e-11e9-8222-59c2702f6c42.png">


When you’re done, scroll down to the `Commit changes` section near the bottom of the edit page. Add a short message explaining your change, like "Add my introduction", then click `Commit changes`.


<img width="1030" alt="add-my-username" src="https://user-images.githubusercontent.com/18093541/63131801-efbd5480-bf8c-11e9-9806-89273f027d16.png">

Once you click `Commit changes`, your changes will automatically be published on your GitHub Pages website. Refresh the page to see your new changes live in action.

:tada: You just made your first commit! :tada:

## Extra Credit: Keep on building!

Change the placeholder Octocat gif on your GitHub Pages website by [creating your own personal Octocat emoji](https://myoctocat.com/build-your-octocat/) or [choose a different Octocat gif from our logo library here](https://octodex.github.com/). Add that image to line 12 of your `index.html` file, in place of the `<img src=` link.

Want to add even more code and fun styles to your GitHub Pages website? [Follow these instructions](https://github.com/github/personal-website) to build a fully-fledged static website.

![octocat](./images/create-octocat.png)

## License

This software is open source under the GNU General Public License v3.0.

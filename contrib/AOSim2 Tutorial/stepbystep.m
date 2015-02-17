% A simple script set up as a step by step guide to AOSim2
% 
% Author: Alexander Rodack
% Date: 2/16/2015
% Software provided by Johanan L. Codona
clear all; clc; close all;

%% A Note About Using This Guide
% While the run button can be pressed to execute this entire tutorial, it
% is recommended that you read through it, and copy/paste the code into the
% command window to execute it.  This will allow you to follow along with
% the comments and execute the code in a step by step fashion.  If you want
% to run sections of it as a whole at one time, that is also possible by
% executing the "Run Section" button with the piece you want to run as the
% active cell.  For those of you that do not know, a section of Matlab
% script that starts with a double % and has a bold title is known as a
% cell.  The cell that has a yellow background (in the default color
% scheme) is the active one.  Clicking the Run Section button will execute
% the commands only in this active cell.

%% Getting Started!
% It is important to keep the updated version of AOSim2 as the version you
% are using.  The easiest way to do this is to make use of command line git
% commands.  GUIs also exist if that floats your boat, but they can be
% somewhat of a crutch.  It is always good to learn a new skill, and using
% command line is a powerful way to do things.
%
% This is easier on Linux than on Windows, and I have no Apple computers,
% but I assume it would be closer to Linux than Windows.  This will provide
% some simple instructions based on Linux, but all the git commands will
% work no matter where you use them as long as you have git installed on
% your computer.
%
% Open the command line tool (Terminal in Linux).
% If you don't have git, type: sudo apt-get install git
% If you have git, you are ready to make a clone of the AOSim2/OPTI528
% branch.
% To do this, simply type: git clone -b OPTI528 https://github.com/jlcodona/AOSim2.git
% This will create a directory with the name AOSim2. If you want to specify
% the name of the directory and where it is located, add a path to the end
% of the command above.  An example is: /home/alex/Desktop/AOSim_git/
% After you type in that command, press enter, and you will some lines
% appearing in Terminal.  There shouldn't be any errors, and the last line
% will read "Checking connectivity...done."
%
% BOOM! You know have AOSim2 on your computer
% 
% To examine this a bit, use the cd command to switch into the directory
% that was just created.  Now type: git branch
% You should see "* OPTI528"  This means everything worked correctly.
% Now type: git status
% You will see: On branch OPTI528. Your branch is up-to-date with 'origin/OPTI528'.
% This means you have the most recent version of the repo.
%
% Once you add a file (a script to run something using AOSim2) to this
% directory, you will need to add it to the repo.  Do this using the
% command: git add <path/to/file>  example: git add stepbystep.m
% Type in git status after doing this, and you should see in green
% "new file:   stepbystep.m"
% This change now needs to be committed.
% Type: git commit. A window will open for you to type in a comment about
% what has changed in the files being commited. Save that file, and the
% commit will go through.  using git commit -a will automatically commit
% all modifications (you will still need to do the changes file.  If you
% have your own git repo, you can sync to it, and push these changes so it
% is always up to date.  To do that, look up how to sync to a remote, and
% use the command: git push.  If you have code that fixes a bug, or is
% something John finds interesting, he will likely have you push it to the
% OPTI528 branch for everyone to be able to use/enjoy.
% 
% Now that you have the software, we will examine how to use it.  There
% will be more on git later.


%% Object Oriented Matlab
% For those of you who are not familiar with Object Oriented Programming
% (OOP), this will provide a little insight.  Mathworks has some good
% tutorial videos (I know from experience) that will walk you through the
% basics of creating a class structure, and using it. I highly recommend
% them if you have never seen OOP before.
%
% Basically, in OOP, you create objects that are of user defined class
% structures.  These are essentially data structures that know how to use
% the data within them to do something.  
%
% This comes to fruition in the classes by means of properties and methods.
% The properties are the data items that store whatever you want (scalars,
% vectors, matrices, cells, strings, doubles, logicals, EVERYTHING that
% is/was/can be done in Matlab).  The methods are the functions that tell
% the class what to do with that stored data.
%
% If you look at a class in AOSim2, or in the tutorial videos, you will see
% that it is broken up into sections.  It will start with the name of the
% class and the superclass structure it is going to inherit its initial
% properties and methods from.  This can be handle, matlab.mixin.Copyable,
% or the name of any user defined class (you will see this a lot in AOSim2)
% Next is a list of properties. There are protected and public properties.
% If you want to learn more, look into the tutorials.  Following the
% properties list are the methods.  The first method is always called the
% Constructor. This method tells the class how to create an object of its
% class type.  This is the place to start when looking at a new class so
% you can understand how to create an object to use in your scripting.  All
% the methods that follow (sometimes called utilities) add functionality to
% the class.  This is the part that makes the data structure know what to
% do with the data stored within it.  Finally, there are overloaded methods
% (methods that have the same name as a method in a superclass to change
% them to fit the current class) and static methods. Again, if you want to
% know more, do the tutorials. They are helpful. Really.
%
% One more note, which you would know if you watched the tutorials or are
% already in the know about OOP. You call a property or method by using a
% dot operator.  This is why you will see a lot of g.name or g.coords.
% Basically, if the property or method is known to the class, you can
% access it by using the dot.

%% Let's Jump In! Creating the (AO)Grid
% Alright, now that some of the logistical stuff is out of the way, lets do
% some stuff.
%
% AOGrid is located in the @AOGrid folder in the AOSim2 section of the
% repository.  The reaon for all the '@' symbols in front of the folder
% names is that it allows for other functions to be included in the folder
% and act as methods in the class, but also maintain the ability to be
% called separate from the class.
%
% Now that you have AOGrid open, take a moment to read the comments at the
% beginning.  These are some notes from John that are important to using
% all of AOSim2 correctly.  Also, John has some great comments, so read
% them.  Some are helpful in understanding what is happening, others are
% good for a laugh or two.
%
% Now look over the properties.  This are things that will be a part of
% every class in AOSim2 (every other class has AOGrid as a superclass).
% Some are fairly straightforward, others might be somewhat harder to
% understand what they are for.  Knowing the properties of AOGrid is less
% important than for some of the other classes, but you should get a basic
% understanding of them.  We will learn more about them as we run into the
% need to use them.  Now take a look at the Constructor method.  You can
% see here how to create an AOGrid object, and the possible input arguments
% that are accepted by the code.  Finally, take some time to look at all
% the other methods that are included.  There again is no real reason to
% explain them all here, and a lot of them are used when others are called.
% I will go into detail about some of them when the need arises.
%
% So let's make a simple AOGrid object named Grid:
Grid = AOGrid(64);

% This creates an AOGrid object that contains a 64x64 array.  The default
% values for data properties seen in the Constructor method are set to the
% object as well. 

% Let's explore a couple of the methods that can quickly become important
% coords and COORDS
% Lets run them and see what we get:
[x,y] = Grid.coords;
[X,Y] = Grid.COORDS;

% Take a look at the results
% You will see that x,y are vectors, and X,Y are meshgrid-like matrices.
% These commands map a real life coordinate system (in meters) to the
% pixels in the AOGrid based on the spacing property (defaults to 0.04)
% and how many pixels you gave to the array when creating the object (64
% in this example script).
% This is very convenient for things like plotting, and for understanding
% what a simulation might be like in physical units.

% grid
% This is another important method. This is used a lot in other classes
% that come down the line, but is useful to look at here.  Calling
% Grid.grid will print the current array stored in the object Grid. If you 
% have a matrix already created somewhere that is the right size, you can 
% set the property grid_ (the actual array is stored here) to that matrix.  
% You can also set grid_ by using the constant method.

% The following code will print what is stored in Grid.grid_ under 3
% different cases:
figure(1)
subplot(1,3,1)
imagesc(Grid.grid)
caxis([-1,1]);
title('Default Array');
subplot(1,3,2)
matrix_A = magic(64);
Grid.grid(matrix_A);
imagesc(Grid.grid)
title(sprintf('Array Set Using grid Method\n'));
subplot(1,3,3)
Grid.constant(1);
imagesc(Grid.grid)
caxis([-1,1]);
title('Array Set Using constant Method');

% Printed in the figure 1 are now the default array values (zeros), the
% array when it is set by the grid method to a matrix that is already
% known, and when it is set by the contant method.  Notice that the array
% is overwritten each time, because AOGrid can store only 1 array at a
% time.

% Finally, take note of the overloaded operators section.  This is defining
% how objects with the class type of AOGrid react to mathematical operator
% commands (+, *, and -).  These operators become very important once we
% get to later classes (AOField especially).

% Spend some time playing around with the Grid and learn what the class is
% capable of doing.  I found that the easiest way to not only get a feel
% for using OOP, but also to begin to understand the power of AOSim2.  Call
% some methods, give inputs to them, and see what happens.  I will give you
% a few of my favorites to get you started:

% Grabbing Values from a matrix at certain coordinate points and making
% them a vector (You will see the power of this when we get to Deformable
% Mirros)
OPL = magic(64);
Grid.grid(OPL);
pistonvec = Grid.interpGrid(x(1,:),y(1,:));

% Create a circle, use Grid to fourier transform it, and then plot the
% complex result without a Cdata error.
R = sqrt(X.^2 + Y.^2);
cyl = R<=0.7;
Grid.grid(cyl);
fgrid = Grid.fft(64);
Grid.grid(fgrid);
figure(2)
subplot(1,2,1)
Grid.plotC(1);
title('OOP Designation');

% This example brings me to an important point about AOSim2.  Whenever you
% use a script that makes use of the .fft command (either from a different
% method, or straight as done in this example), the fftgrid_ property is
% set and cached.  This means you have to clear the property if you want to
% do a different FFT. It is written this way to save time from having to do
% the same FFT over and over, so if the property is not empty, the program
% assumes you want to use the cached copy and avoid unnecssary computation.
% Clearing the property is simple.  Use the touch method.
Grid.touch;

% Another note.  You don't have to use the OOP designation to call methods.
% They are all written such that the first input is the class object, which
% means you can get the same effect by using standard Matlab notation
clear fgrid;
grid(Grid,cyl);
fgrid = fft(Grid,64);
grid(Grid,fgrid);
subplot(1,2,2)
plotC(Grid,1);
title('Standard Matlab Function Designation');
touch(Grid);

% You can see in figure 2 that calling the methods either way nets the
% exact same result.  Pretty cool, right?

% Keep looking through the methods in AOGrid and have some fun! The more
% you know about this class, and how to use the methods for the object, the
% better off you will be as we add complexity and move forward.

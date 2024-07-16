function dlgex(trialsFolderBase, imagesFolderBase)

%This is a function that simply serves as EXAMPLE CODE to show the basic
%workings of inputsdlg.m, which is a bit tough to crack otherwise

%In this example we will set up the dialog directly (i.e. not in a separate
%function)

%% Setup

%Create a set of empty cell arrays (or structure of cell arrays) to hold
%values (elements, prompts, default answer) for each entry in the dialog:
elements = struct('type', {}, 'style', {}, 'format', {}, 'limits', {}, 'size', {});  %Within ELEMENTS, there are multiple possible element properties,
                                                                                     %these are defined at the bottom of this file.  We should create
                                                                                     %an empty cell-array field for every property we will use, even 
                                                                                     %though in most cases we can get away with not doing it
prompts = {};
defaultanswer = {};


%% Define dialog box elements

%Note that the indices to DEFAULTANSWER and PROMPTS should be consecutive,
%starting at 1 for the "first" element.  The ELEMENTS entry works
%differently - element order will increase from left to right columns, and
%then row-to-row.  The index to ELEMENTS [e.g. (1,2) below] indicates 
%row/column position of the dialog element.  Thus in this example, the text 
%label is placed at row 1, column 2.  Since there is no other element in 
%row 1 (columns 1 and 3 are empty), this corresponds to index=1 for 
%DEFAULTANSWER and PROMPTS.  The number of columns in the dialog will be
%set by the maximum value found in ELEMENTS(r,c).  I do not believe that 
%there is a limit to the number of columns that may be requested.

%If you dig into the inputsdlg.m function, what is called ELEMENTS here is
%called FORMATS there...but FORMATS.FORMAT is confusing so here I have used
%ELEMENTS for clarity.

%The following types of dialog elements are available, along with sample syntax:

%Text Label - these are useful for delimiting the dialog or leaving
%information for the user.  They cannot be interacted with.
elements(1,1).type = 'text';  %TYPE 'text' does NOT mean text entry box 
elements(1,1).style = 'text'; 
defaultanswer{1} = 'none';  %we must include a default answer, even though the text label cannot be interacted with
prompts{1} = '------------ This is just a text label ------------';

%Text Entry Box
elements(2,1).type = 'edit';  %TYPE 'edit' creates a generic entry box 
elements(2,1).format = 'text';  %FORMAT 'text' makes it return text
elements(2,1).size = [100 0];  %For a text entry box it is useful to adjust the width of the element (but not height)
defaultanswer{2} = '';  %Default answer for a text entry box is a string; if it is empty there will be no text in the box to start
prompts{2} = 'Output file base: ';

%Radio Buttons - Text
radioValues = {'Image', 'Gabor'};
elements(3, 1).format = 'text';
elements(3, 1).type = 'list';
elements(3, 1).style = 'radiobutton';
elements(3, 1).items = radioValues;
defaultanswer{3} = 'Image';  %Unlike listbox and popup menus, TEXT radio buttons deal in and return literal values
prompts{3} = 'Select expt test image type';

%Checkbox
elements(4,1).type = 'check';
elements(4,1).style = 'checkbox';
elements(4,1).format = 'integer';  %checkboxes return 0/1 integers
elements(4,1).limits = [0 1];  %so limits should be 0/1
defaultanswer{4} = 1;  %This will be checked by default
prompts{4} = 'Threshold?';

%Pop-up Menu
popupValues = {'no-test' 'booth' 'desk'};
elements(5,1).type = 'list';
elements(5,1).style = 'popupmenu';
elements(5,1).items = popupValues;  %Could assign directly, but this makes it easier to get the text 'Value N' from ANSWER{7} if necessary
defaultanswer{5} = 2;
prompts{5} = 'Select a value';

% trials
elements(6, 1).format = 'file';
elements(6, 1).type = 'edit';
elements(6, 1).style = 'edit';
elements(6, 1).items = {'*.mat'};
defaultanswer{6} = trialsFolderBase;
prompts{6} = 'Trials file';

%Radio Buttons - Integer
radioValues = [1 2 3];
elements(7,1).format = 'integer';
elements(7,1).type = 'list';
elements(7,1).style = 'radiobutton';
elements(7,1).items = radioValues;
defaultanswer{7} = 1;  %Integer radio buttons deal in indices like listbox and popup menus (also, default is broken, just use 1)
prompts{7} = 'Select a block number';

% images
elements(8, 1).format = 'dir';
elements(8, 1).type = 'edit';
elements(8, 1).style = 'edit';
%elements(7, 1).items = {'*.m'};
defaultanswer{8} = imagesFolderBase;
prompts{8} = 'Image folder';

%Text Entry Box
elements(9,1).type = 'edit';  %TYPE 'edit' creates a generic entry box 
elements(9,1).format = 'text';  %FORMAT 'text' makes it return text
elements(9,1).size = [100 0];  %For a text entry box it is useful to adjust the width of the element (but not height)
defaultanswer{9} = 'params';  %Default answer for a text entry box is a string; if it is empty there will be no text in the box to start
prompts{9} = 'Params fcn: ';


%The function apparently also allows "tables" but I have not investigated
%those.

%So...neat!  Lots of possible elements!  Design and position them to your
%heart's content!



%Provide a name for the dialog
name = 'Ethological Salience Expt';



%% Run the dialog
[answer,cancelled,entryError] = inputsdlg(prompts,name,elements,defaultanswer);

%If dialog is cancelled, we can quit now
if cancelled == 1
    return
end

%If there was a dialog entry error, notify and quit now
if entryError == 1
    disp('There was an error with one of the entries in the stimulus dialog box!  Quitting!  Please try again!')
    return
end




%% Display the results
%In the real world you will deal the values from ANSWER{} out to your
%variables of interest.  Recall that ANSWER{1} and ANSWER{6} correspond to 
%the text labels above and are empty
% for i = 1:length(answer)
%     disp(answer{i})
% end

fprintf('output file base %s\n', answer{2});
fprintf('test type: %s\n', answer{3});
fprintf('threshold? %d\n', answer{4});
fprintf('test location: %s\n', popupValues{answer{5}});
fprintf('trials file: %s\n', answer{6});
fprintf('block number %d\n', answer{7});
fprintf('images folder: %s\n', answer{8});
fprintf('images load params: %s', answer{9});


% Try to load trials file
Y=load(answer{6});
if any(contains(fieldnames(Y), 'blocks'))
    % Check how many blocks, and prompt user to pick the block
    numBlocks = length(Y.blocks);
    iBlockNumber = answer{7};
    fprintf('Block %d has %d trials\n', iBlockNumber, height(Y.blocks{iBlockNumber}));
    if iBlockNumber > numBlocks
        error('Bad block number.');
    else
        trials = Y.blocks{iBlockNumber};
    end
elseif any(contains(fieldnames(Y), 'trials'))
    trials = Y.trials;
end

% try to load images
img = imageset(answer{8}, answer(9));



% Now try to run the thing
results = run_etholog_single(answer{2}, 'Test', popupValues{answer{5}}, 'Trials', trials, 'Threshold', logical(answer{4}), 'ExperimentTestType', answer{3}, 'Images', img);




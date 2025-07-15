## Generating trials for specific experiment types

Make sure *ethDataRoot* and *ethImageRoot* are set via **local_ethosal** or the equivalent. 
This can be done on any machine, but the *ethImageRoot* should contain the same image set you use 
here.

Load the imageset you will use - commands for each experiment type are below. The image set names refer 
to the cclab-images repo (this repo's folder should be the same as *ethImageRoot*).

### Ethological salience and goal-directed attention, baby faces

Using black/white baby faces in *nat/* and *tex/* folders. Originally, we referred to the black&white images 
as *natural* images, as opposed to *texture* images.  Later, when we added images *from nature*, i.e. trees, etc, 
we used the folders *nature/* and *nature-tex/*.

The params file *paramsCircEdge256.m* has these parameters:

    function Y = paramsCircEdge256()
        Y.Subfolders={ ...
            'H','nat';'L','tex'
        };
	    Y.MaskParameters = [256,128,100,100];
    end
    
The trials were generated with these commands:

    img=imageset(fullfile(ethImgRoot,'MoreBabies'), 'paramsCircEdge256')
    [blocks, inputArgs, parsedResults, scriptName] = generateEthBlocksImgV2(img.BalancedFileKeys, [25,25,0;25,0,25;50,0,0],Base=4,NumBlocks=2);
    trial set 1: 600 trials
    Block 1 has 300 elements
    Block 2 has 300 elements
    trial set 2: 600 trials
    Block 1 has 300 elements
    Block 2 has 300 elements
    trial set 3: 800 trials
    Block 1 has 400 elements
    Block 2 has 400 elements
    
There are three separate sets of trials generated, each broken into two blocks. The second argument to *generateEthBlocksImgV2* is 
`[25,25,0;25,0,25;50,0,0]`. This is a three-row matrix, where each row is a set of trials. Within each 
row there are three columns, each is the number of image pairs used to generate trials that are 
*neutral*, *left*-goal-directed, and *right*-goal-directed, respectively. 

For neutral type-trials, both sides are tested, so there are 16 trials for each image pair. 

For goal-directed trials (either *lef* or *right*), there are 8 trials for each image pair.

So, with the command above, three sets of trials are generated. The first two are for goal-directed trials, and the last is for plain ethological salience.

The goal directed data sets created here have only 66% cue accuracy, meaning that even though the cue is directed to one side or the other, 
it is only *correct* 2 out of 3 times. Out of concern that the cue wasn't reliable enough, we generated additional datasets using
`[20,60,0;20,0,60]`. These data sets have cues that are 80% reliable.

The filenames used in expts are

|filename|contents|Num trials|
|--------|--------|----------|
|rimg_exp_50pair_25l25b| 50 image pairs, 25 left, 25 both|600 trials|
|rimg_exp_50pair_25r25b| 50 image pairs, 25 right, 25 both|600 trials|
|rimg_exp_50pair_50b| 50 image pairs, 50 both|800 trials|
|rimg_exp_60-20-left-A|80 image pairs, 20 both, 60 left|800 trials|
|rimg_exp_60-20-right-A|80 image pairs, 20 both, 60 right|800 trials|

### Ethological salience, three categories (baby, burgers, bushes)

### Ethological salience, burgers

Use food images in folder *food/* and *food-tex/*. 

The params file *paramsCircEdge256_food.m* has the following parameters:

    function Y = paramsCircEdge256_food()
        Y.Subfolders={ ...
        'F','food';'f','food-tex';
        };
        Y.MaskParameters = [256,128,100,100];
    end

The high-salience images are taken from the *food/* subfolder, and low-salience images are taken from *food-tex/*.

```
img=imageset(fullfile(ethImgRoot,'MoreBabies'), 'paramsCircEdge256_food');
[blocks, inputArgs, parsedResults, scriptName] = generateEthBlocksImgV2(img.BalancedFileKeys, [50,0,0], FolderKeys={'F';'f'},Base=4, NumBlocks=3, FlipPair=true);
makeEthologInput(ethDataRoot, 'rimg', 'exp', '50food_neutral', img, blocks{:}, inputArgs, parsedResults, scriptName);
```

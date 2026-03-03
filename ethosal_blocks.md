# Generating trial blocks for ethosal

Here's how I generated trials for the ethosal experiment. 

## Trial types and definitions

Each trial displays *two* images

The blocks of trials test each image in a variety of combinations and arrangements to eliminate any bias due to the makeup of the trials. 

## setup

Will need *cclab_ethosal* as well as *cclab_matlab_tools*. 

Questions to answer before moving on:

1. What mix of images will be used? Baby faces, food, nature? Color or black/white? Each corresponds to a folder within the imageset root folder. Assign a letter to each folder used - this letter is used as the *folder key*.

    In all ethological salience psychophysics expts, we use the *MoreBabies* archive in [the cclab image archive](https://github.com/djsperka/cclab-images). For our baby face trials, we use the black/white baby face images (in folder *nat*), and their texturized counterparts (in folder *tex*). The baby faces in *nat* are *high salience*, and we assign the letter 'H' as the folder key. The textures in *tex* are *low salience*, and we assign the letter 'L' as the folder key. 

2. How many "neutral", "left", and "right" image pairs? There are 16 (8) trials per image pair for "neutral" ("left" or "right") trials.

    Multiplicity of trials depends on the number of image pairs used, and the type of trials produced. For each image pair, there are 4 arrangements of the images (HH, HL, LH, LL). The *side* to be tested can be left or right, there can be a change or no-change. Thus, for the neutral case, there are 16 trials per image pair:

    > (image arrangement, 4) * (test side, 2) * (change/no change, 2) = 4x2x2 = 16. 

    Similarly, for goal-directed trials, only one of the two sides is tested, so there are 8 trials per image pair:

    > (image arrangement, 4) * (test side, 1) * (change/no change, 2) = 4x1x2 = 8.

    Thus, the choice of the number of image pairs, and for which type of trial, "neutral", "left", or "right",  determines the total number of trials generated. 

3. How many blocks should the trials be split into? 

    Once trials are generated, they can be split in to blocks. The number of blocks depends on how long your trials take, and how long you want your subject top go without a break.

4. Will the trials be cued? If so, which cue -*left* or *right*?

    For goal-directed trials, you can request a visible cue on-screen. 

5. Will image pairs use the same image, or different images? 

    The image pairs can use the same, or different, image for both the left- and right-hand side. 


## Examples

### Goal directed trials, baby faces only

1. Baby faces and textures. The imageset can be loaded with this command:

    ```
    img=imageset(fullfile(ethImgRoot, 'MoreBabies'), 'paramsCircEdge256')
    Found 100 images in 'H' folder /home/dan/work/cclab/cclab-images/MoreBabies/nat
    Found 100 images in 'L' folder /home/dan/work/cclab/cclab-images/MoreBabies/tex
     
    img = 
    
      imageset with properties:
    
        Extensions: {'bmp'  'jpg'  'png'}
        Root: '/home/dan/work/cclab/cclab-images/MoreBabies'
        Name: 'MoreBabies'
        ParamsFunc: 'paramsCircEdge256'
        Subfolders: {2×2 cell}
        OnLoadFunc: @(x)uint8(((double(imresize(x,[m(1),m(1)]))-128).*M)+128)
        IsBalanced: 1
        BalancedFileKeys: {100×1 cell}
        MissingKeys: {0×1 cell}
        Bkgd: [3×1 double]
        IsUniform: 1
        UniformOrFirstRect: [0 0 256 256]
        MaskParameters: [256 128 100 100]
    ```

2. There will be sets of trials with 60 image pairs for goal-directed trials, and 20 image pairs for neutral (both left- and right-tested trials). Thus, the total number of trials will be `60\*8 + 20\*16 = 480 + 320 = 800`

3. Split the 800 trials into 3 blocks

4. Yes, cue both left- and right- goal-directed trials.

5. Yes, use same image for both left and right

The command line to generate the trials is:

```
>> [blocks,inputArgs,parsedResults,scriptName]=generateEthBlocksImgV2(img.BalancedFileKeys, [20,60,0;20,0,60], 'FlipPair', true, 'NumBlocks', 8, 'CueSide', [1;2], 'FolderKeys', {'H';'L'});
i=1: N=20, 320 trials generated
i=2: N=60, 480 trials generated
i=1: N=20, 320 trials generated
i=3: N=60, 480 trials generated
trial set 1: 800 trials
Block 1 has 100 elements
Block 2 has 100 elements
Block 3 has 100 elements
Block 4 has 100 elements
Block 5 has 100 elements
Block 6 has 100 elements
Block 7 has 100 elements
Block 8 has 100 elements
trial set 2: 800 trials
Block 1 has 100 elements
Block 2 has 100 elements
Block 3 has 100 elements
Block 4 has 100 elements
Block 5 has 100 elements
Block 6 has 100 elements
Block 7 has 100 elements
Block 8 has 100 elements
```


### Create input file for ethosal

The table(s) created cannot be used directly in ethosal. An input file with additional info must be constructed. The first command, *makeEthologInput*, will create a *mat-*file that can be used as input. 

Use the results of *generateEthBlocksImgV2* command to run run *makeEthologInput* for each set of blocks. The input args are:

- ethDataRoot: root folder for data files. New mat file will be put in ethDataRoot/input
- 'rimg', 'exp': these strings become part of the new file name. DO NOT CHANGE THESE VALUES -- the ethosal dialog will expect to find these strings in the filename.
- 'gd-example-60-20-L' - this should change for each file. It is a unique string in the filename to identify these particular trials.
- img - the imageset used
- blocks{1} - the blocks to put into this file
- inputArgs, parsedResults, scriptName - these are returned from *generateEthBlocksImgV2*

Notice that 'generateEthBlocksImgV2' is called twice. Once, using blocks{1} and the string 'gd-example-60-20-L', for the left-goal-directed trials. The second, using blocks{2} and 'gd-example-60-20-R' is for the right-goal-directed trials.

This form of input file isn't useful when you are doing goal-directed trials. In that case, you normally run a block of "left", then a block of "right", and so on. The etholog dialog will require you to select a different file each time: first the *left* file (select block 1), then the *right* file (select block 1), then *left* (select block 2), and so on. When we have 8 blocks per side, 16 blocks in all, this is tedious and error-prone.

```
>> makeEthologInput(ethDataRoot, 'rimg', 'exp', 'gd-example-60-20-L', img, blocks{1}, inputArgs, parsedResults,scriptName)
nargin is 9
Saved to /home/dan/work/cclab/ethdata/input/rimg_exp_gd-example-60-20-L.mat

ans =

    '/home/dan/work/cclab/ethdata/input/rimg_exp_gd-example-60-20-L.mat'

>> makeEthologInput(ethDataRoot, 'rimg', 'exp', 'gd-example-60-20-R', img, blocks{2}, inputArgs, parsedResults,scriptName)
nargin is 9
Saved to /home/dan/work/cclab/ethdata/input/rimg_exp_gd-example-60-20-R.mat

ans =

    '/home/dan/work/cclab/ethdata/input/rimg_exp_gd-example-60-20-R.mat'
```


For goal-directed files like the example above, make a single, combined input file that interleaves the left-goal-directed and right-goal-directed blocks into a single file. No need to re-open files to select a new block. Just run the command and follow the prompts. 


```
>> makeBlockset
```

This script will prompt you to select the LEFT goal-directed file, then the right. It will interleave the blocks from the two files so that there is a left-block, then a right block, and so on. 

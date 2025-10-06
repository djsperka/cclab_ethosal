# Ethological Salience in MangunLab
Modifications and adaptations for work with EEG in Mangun Lab. 

## Branch: mangun_adaptation

The changes required are _really_ in `run_ethologV2.m`, `ethologV2.m`, `ethodlg.mlapp`, 
and `ethodlg_exported.m`. Additional settings are required, as well as different hardware interactions, and it gets a little messy. I may eventually merge it to main.

### Hardware
####io64
There is a mythical mex file called `io64` that people use (Windows only I think) to treat a parallel port as an 8-bit DIO device. 
Here is a [link to an archived web page](https://web.archive.org/web/20210903151747/http://apps.usd.edu/coglab/psyc770/IO64.html). 

The eeg system used at the Mangun Lab has an 8-bit digital input that is sampled along with the eeg signal (I don't know what freq)
and recorded with the data. Used for synchronizing with other data streams, and for encoding experimental parameters within the 
eeg data stream itself.

####IO64Device
I encapsulated the small bit of code one needs to use the io64 device into a Matlab class. One must know the `address` - the physical address of the IO port.

```

% Instantiate object using physical address
iodevice = IO64Device(hex2dec('03FB8'));  % address in hex

% output a value.
n=99;
iodevice.outp(n);	% 0 <= n <= 255

% input a value
i = iodevice.inp();
fprintf('The value read was %d\n', i);


```


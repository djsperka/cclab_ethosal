function showStim12(w, imgset, keys, img2Func, t1, tGap, t2)
%showStim12 display stim as in etholog
%   For each key in keys, display it, then display it again using img2Func.
%   The values t1, tGap, and t2 are the times for stim1, gap, stim2, in 
%   seconds. 

    for i=1:length(keys)
        imgset.flip(w, keys{i});
        WaitSecs(t1);
        Screen('Flip', w);
        WaitSecs(tGap);
        imgset.flip(w, keys{i}, img2Func);
        WaitSecs(t2);
        Screen('Flip', w);
        input('Hit a key for next image.');
    end
end
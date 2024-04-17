function showStim12(w, imgset, keys, img1Func, img2Func, t1, tGap, t2)
%showStim12(w, imgset, keys, img2Func, t1, tGap, t2) display stim as in
%etholog trials.
%   For each key in keys (celll array), display it using img1Func 
%   (function_handle or []), then display it again using img2Func.
%   The values t1, tGap, and t2 are the times for stim1, gap, stim2, in 
%   seconds. 

    if isempty(img1Func)
        img1Func = @deal;
    end
    if isempty(img2Func)
        img2Func = @deal;
    end
    for i=1:length(keys)
        imgset.flip(w, keys{i}, img1Func);
        WaitSecs(t1);
        Screen('Flip', w);
        WaitSecs(tGap);
        imgset.flip(w, keys{i}, img2Func);
        WaitSecs(t2);
        Screen('Flip', w);
        input('Hit a key for next image.');
    end
end
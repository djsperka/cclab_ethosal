phase = 0;
sc = 100.0;
freq = .05;
tilt = 0;
contrast = 5.0;
aspectratio = 1.0;

tw = 256;
th = 256;
x=tw/2;
y=th/2;
grect=[0,0,256,256];

gtex1 = CreateProceduralGabor(w, tw, th, 0, [0.5 0.5 0.5 0.0]);
gtex2 = CreateProceduralGabor(w, tw, th, 0, [0.5 0.5 0.5 0.0]);
rect1 = CenterRectOnPoint(grect, 250, 300);
rect2 = CenterRectOnPoint(grect, 550, 300);
params = [phase, freq, sc, contrast, aspectratio, 0, 0, 0];
params1 = [phase, freq, sc, contrast, aspectratio, 0, 0, 0];
params2 = [phase, freq, sc, contrast, aspectratio, 0, 0, 0];


%Screen('DrawTexture', w, gtex1, [], [], 0, [], [], [], [], kPsychDontDoRotation, [phase+180, freq, sc, contrast, aspectratio, 0, 0, 0]);
%Screen('DrawTextures', w, [gtex1, gtex2], [], [rect1;rect2]', [0,90], [], [], [], [], kPsychDontDoRotation, [params;params]');

% works for two gabor
%Screen('DrawTextures', w, [gtex1, gtex1], [], [rect1;rect2]', [0,90], [], [], [], [], kPsychDontDoRotation, [params;params]');

Screen('DrawTextures', w, [gtex1, gtex1], [], [rect1;rect2]', [0,90], [], [], [], [], kPsychDontDoRotation, [params;params]');


%Screen('DrawTexture', w, [gtex, [], [], 90, [], [], [], [], kPsychDontDoRotation, [phase+180, freq, sc, contrast, aspectratio, 0, 0, 0]);
%Screen('DrawTextures', w, gtex1, [], rect1, 0, [], [], [], [], kPsychDontDoRotation, params);
%Screen('DrawTextures', w, [gtex1, gtex2], [], [rect1;rect2]', [0,90], [], [], [], [], kPsychDontDoRotation, );
%Screen('DrawTextures', windowIndex, [tex1a tex2a],   [], [stim1Rect;stim2Rect]');

Screen('Flip', w);
























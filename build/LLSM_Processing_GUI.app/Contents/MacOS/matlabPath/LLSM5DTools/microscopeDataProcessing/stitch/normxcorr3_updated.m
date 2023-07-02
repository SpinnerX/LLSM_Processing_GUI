function C = normxcorr3_updated(T, A, shape)
% C = normxcorr3(TEMPLATE, IMAGE, SHAPE)
%
%       TEMPLATE - type double, ndims==3, size <= size of image
%       IMAGE    - type double, ndims==3
%       SHAPE    - one of: 'valid', 'same', 'full'. same as conv2 shape parameter
%                  'full' by default
%
%       C        - values in [-1,1]. size depends on SHAPE
%
% the syntax of this function is identical to Matlab's
% normxcorr2, except that it's been extended to 3D matrices,
% and, the SHAPE parameter has been introduced as a convenience
%
% the SHAPE parameter has the same effect as it does for the CONVN function.
% see the documentation for CONVN for a more detailed explanation
%
% caveat emptor: this function does not perform the argument checking that
% normxcorr2 does. for example, it doesn't ensure that std(T(:))~=0
%
% daniel eaton, 2005, danieljameseaton@gmail.com
%
% xruan (11/20/2022): adapted from normxcorr3.m and optimize performance for some bottleneck steps.
% xruan (05/06/2023): add support for 1d and 2d matrix


if nargin<3
	shape = 'full';
end

if ndims(A)>3 || ndims(T)>3
	error('A and T must be no more than 3 dimensional matrices');
end

szT = size(T, 1 : 3);
szA = size(A, 1 : 3);

if any(szT>szA)
	error('template must be smaller than image');
end

pSzT = prod(szT);

szOut = szT + szA - 1;

% compute the numerator of the NCC
% emulate 3D correlation by rotating templates dimensions
% in 3D frequency-domain correlation is MUCH faster than the spatial-domain
% variety
rotT = flipdim(flipdim(flipdim(T,1),2),3); % this is rot90 in 3d
fftRotT = fftn(rotT,szOut);
fftA = fftn(A,szOut);
corrTA = real(ifftn(fftA.*fftRotT));
clear rotT fftRotT fftA;

sumT = sum(T(:));
denomT = std(T(:));
clear T;

% make the running-sum/integral-images of A and A^2, which are
% used to speed up the computation of the NCC denominator
intImgA = integralImage(A,szT);

num = (corrTA - intImgA*sumT/pSzT ) / (pSzT-1);
clear corrTA; 

% compute the denominator of the NCC
intImgA2 = integralImage(A.*A,szT);

denom = denomT * sqrt(max(intImgA2 - (intImgA.^2)/pSzT, 0) / (pSzT-1) );
clear A intImgA intImgA2;

% compute the NCC
% s = warning('off', 'MATLAB:divideByZero');
C = num ./ (denom + eps) .* (denom ~= 0);
% s = warning('on', 'MATLAB:divideByZero');

% replace the NaN (if any) with 0's
% zeroInd = find(denomA==0);
% C(zeroInd) = 0;
% try
%     C = replace_nan_inf_with_value(C, 0);
% catch ME
%     disp(ME)
%     C(isnan(C)) = 0;
% end

switch( lower(shape) )
	case 'full'
	case 'same'
		szTp = fix((szT-1)/2);
		C = C( szTp(1)+1:szTp(1)+szA(1), szTp(2)+1:szTp(2)+szA(2), szTp(3)+1:szTp(3)+szA(3) );
	case 'valid'
		C = C(szT(1):end-szT(1)+1,szT(1):end-szT(2)+1,szT(3):end-szT(3)+1);
	otherwise
		error(sprintf('unknown SHAPE %s, assuming FULL by default', shape));
end

function integralImageA = integralImage(A,szT)
% this is adapted from Matlab's normxcorr2

szA = size(A, 1 : 3);

B = zeros( szA+2*szT-1, class(A));
% B( szT(1)+1:szT(1)+szA(1), szT(2)+1:szT(2)+szA(2), szT(3)+1:szT(3)+szA(3) ) = A;
indexing3d_mex(B, [szT+1, szT+szA], A);

s = cumsum(B,1);
clear B;
% c = s(1+szT(1):end,:,:)-s(1:end-szT(1),:,:);
c = crop3d_mex(s, [1 + szT(1), 1, 1, size(s, 1 : 3)]) - crop3d_mex(s, [1, 1, 1, size(s, 1) - szT(1), size(s, 2 : 3)]);
s = cumsum(c,2);
% c = s(:,1+szT(2):end,:)-s(:,1:end-szT(2),:);
c = crop3d_mex(s, [1, 1 + szT(2), 1, size(s, 1 : 3)]) - crop3d_mex(s, [1, 1, 1, size(s, 1), size(s, 2) - szT(2), size(s, 3)]);
s = cumsum(c,3);
% integralImageA = s(:,:,1+szT(3):end)-s(:,:,1:end-szT(3));
integralImageA = crop3d_mex(s, [1, 1, 1 + szT(3), size(s, 1 : 3)]) - crop3d_mex(s, [1, 1, 1, size(s, 1), size(s, 2), size(s, 3) - szT(3)]);




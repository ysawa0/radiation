%% assumes that one plane has only one contour

clear all;

%% SET INITIAL PARAMETERS
% for patient 4, ptv is 9, bladder is 2, rectum is 5
ptvID = 9;
bladderID = 2;
rectumID = 5;
patient_number = 2;

containing_folder = strcat('UCLA_PR_',num2str(patient_number));%create folder path from patient number
structureset_file_path = strcat('UCLA_PR_',num2str(patient_number),'/structureset.dcm');%create pathname for structure set file

structureSetInfo=dicominfo(structureset_file_path);%structure set file metadata
numStructures=length(fieldnames(structureSetInfo.StructureSetROISequence));%total number of structures in the structure set

%% To CREATE MAPPING OF ROI NUMBER AND NAMES
roiList=cell(numStructures,2);
for j = 1:numStructures
    item_number_string=strcat('Item_',num2str(j));% to generate strings 'Item_1','Item_2', etc.
    roiID=structureSetInfo.StructureSetROISequence.(item_number_string).ROINumber;
    roiList{roiID,1}=structureSetInfo.StructureSetROISequence.(item_number_string).ROIName;%column 1 contains names
    roiList{roiID,2}=roiID;%column 2 contains ROI Numbers
end

%% To DETERMINE ITEM NUMBER CORRESPONDING TO ROI NUMBER in ROI Contour
% Sequence object

numContourSeqs = length(fieldnames(structureSetInfo.ROIContourSequence));
for k = 1:numContourSeqs
    item_number_string=strcat('Item_',num2str(k));
    current_roi_number=structureSetInfo.ROIContourSequence.(item_number_string).ReferencedROINumber;
    if current_roi_number==ptvID
        ptv_Item_no=strcat('Item_',num2str(k));
    end
    if current_roi_number==bladderID
        bladder_Item_no=strcat('Item_',num2str(k));
    end
    if current_roi_number==rectumID
        rectum_Item_no=strcat('Item_',num2str(k));
    end
end

%% DETERMINE ROW SPACING AND COLUMN SPACING
ImageSOP = structureSetInfo.ROIContourSequence.(ptv_Item_no).ContourSequence.Item_1.ContourImageSequence.Item_1.ReferencedSOPInstanceUID;
imagei = dicominfo(strcat(containing_folder,'/CT.',ImageSOP,'.dcm'));
rowSpacing = imagei.PixelSpacing(1);
columnSpacing = imagei.PixelSpacing(2);
sliceSpacing = imagei.SliceThickness;%assume slice thickness is always set and that there is no gap b/w slices
width = imagei.Width;
height = imagei.Height;

%% GET PTV, BLADDER AND RECTUM CONTOURS AND MASKS
% ptvBlock is the entire solid ptv - an object contour
% ptvContourBlock contains contour slices derived from the patient
% coordinate system translated to pixel coordinate system
 
[ptvBlock, ptvContourBlock]=getContoursFull(structureSetInfo, ptv_Item_no, width, height, patient_number);
[bladderBlock, bladderContourBlock]=getContoursFull(structureSetInfo, bladder_Item_no, width, height, patient_number);
[rectumBlock, rectumContourBlock]=getContoursFull(structureSetInfo, rectum_Item_no, width, height, patient_number);

%% show contours and object slices
% ptvContour = ptvContourBlock(:,:,15);
% ptvFilled = ptvBlock(:,:,15);
% ptvSmoothContour = bwperim(ptvFilled);
% imshow(ptvContour); title('PTV Contour');
% figure, imshow(ptvSmoothContour); title('PTV Smoothened Contour');
% figure, imshow(ptvFilled); title('PTV Filled');
% ***********************************

%% Convert rough, slightly unconnected contours to smooth contours. Since
% the objects are 3D, the first and last slice should be filled to give a
% true outline; only ptv countours are smoothened since only ptv contours
% are needed. for OARs, solid masks are needed
ptvOutline3D = zeros(size(ptvBlock));
for i = 2:(size(ptvBlock,3)-1)
    ptvOutline3D(:,:,i) = bwperim(ptvBlock(:,:,i));
end
ptvOutline3D(:,:,1) = ptvBlock(:,:,1);
ptvOutline3D(:,:,size(ptvBlock,3)) = ptvBlock(:,:,size(ptvBlock,3));

%% SEPARATION OF OARs into intersecting and non-intersecting parts

rectumIntersecting = rectumBlock&ptvBlock;
rectumNonIntersecting = rectumBlock - rectumIntersecting;
bladderIntersecting = bladderBlock&ptvBlock;
bladderNonIntersecting = bladderBlock - bladderIntersecting;

%% Get positions of all ON pixels in the organ masks and the smooth ptv contour object
% bladderSub contains pixel positions of all ON pixels in the solid bladder
% mask, and rectumSub for the rectum. ptvSub has pixel positions of all ON
% pixels in the smoothened outline mask of the ptv

%INITIALIZE
numIntersectingBladderVoxels = nnz(bladderIntersecting);
numNonIntersectingBladderVoxels = nnz(bladderNonIntersecting);
numIntersectingRectumVoxels = nnz(rectumIntersecting);
numNonIntersectingRectumVoxels = nnz(rectumNonIntersecting);
numPtvVoxels = nnz(ptvOutline3D);
bladderIntersectingSub = zeros(numIntersectingBladderVoxels,4);
bladderNonIntersectingSub = zeros(numNonIntersectingBladderVoxels,4);
rectumIntersectingSub = zeros(numIntersectingRectumVoxels,4);
rectumNonIntersectingSub = zeros(numNonIntersectingRectumVoxels,4);
ptvSub = zeros(numPtvVoxels,3);

%FIND LINEAR INDICES OF ALL NON ZERO VOXELS
bladderIntersectingLin = find(bladderIntersecting);
bladderNonIntersectingLin = find(bladderNonIntersecting);
rectumIntersectingLin = find(rectumIntersecting);
rectumNonIntersectingLin = find(rectumNonIntersecting);
ptvLin = find(ptvOutline3D);

%CONVERT LINEAR INDICES TO SUBSCRIPTS
[bladderIntersectingSub(:,1), bladderIntersectingSub(:,2), bladderIntersectingSub(:,3)] = ind2sub(size(bladderIntersecting),bladderIntersectingLin);
[bladderNonIntersectingSub(:,1), bladderNonIntersectingSub(:,2), bladderNonIntersectingSub(:,3)] = ind2sub(size(bladderNonIntersecting),bladderNonIntersectingLin); 
[rectumIntersectingSub(:,1), rectumIntersectingSub(:,2), rectumIntersectingSub(:,3)] = ind2sub(size(rectumIntersecting),rectumIntersectingLin);
[rectumNonIntersectingSub(:,1), rectumNonIntersectingSub(:,2), rectumNonIntersectingSub(:,3)] = ind2sub(size(rectumNonIntersecting),rectumNonIntersectingLin);
[ptvSub(:,1), ptvSub(:,2), ptvSub(:,3)] = ind2sub(size(ptvOutline3D),ptvLin);

%% WEIGHTED EUCLIDEAN DISTANCE
% d((i,j,k),(a,b,c))=sqrt[1(i-a)^2+alpha(j-b)^2+beta(k-c)^2], where the
% ratio of the sampling intervals in the three axes is 1:alpha:beta for
% row:column:plane viz 1:columnSpacing/rowSpacing:heightSpacing/rowSpacing
alpha = columnSpacing/rowSpacing;
beta = sliceSpacing/rowSpacing;

%% CALCULATE MINIMUM DISTANCE FROM EACH OAR POINT TO THE PTV OUTLINE (currently for bladderIntersecting

for oarVoxel = 1:numIntersectingBladderVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-bladderIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-bladderIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-bladderIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    bladderIntersectingSub(oarVoxel,4) = -1*minimumDistance;
end
[v_bladderIntersecting, r_bladderIntersecting] = hist(bladderIntersectingSub(:,4));

%% do for Non Intersecting part of the Bladder

for oarVoxel = 1:numNonIntersectingBladderVoxels
    minimumDistance=1000000;
    for ptvVoxel = 1:numPtvVoxels
        distance = sqrt((ptvSub(ptvVoxel,1)-bladderNonIntersectingSub(oarVoxel,1))^2+(alpha*(ptvSub(ptvVoxel,2)-bladderNonIntersectingSub(oarVoxel,2)))^2+(beta*(ptvSub(ptvVoxel,3)-bladderNonIntersectingSub(oarVoxel,3)))^2);
        minimumDistance = min(minimumDistance, distance);
    end
    bladderNonIntersectingSub(oarVoxel,4) = minimumDistance;
end
[v_bladderNonIntersecting, r_bladderNonIntersecting] = hist(bladderNonIntersectingSub(:,4));

%%

r_bladder = horzcat(r_bladderIntersecting, r_bladderNonIntersecting);
v_bladder = horzcat(v_bladderIntersecting, v_bladderNonIntersecting);
cum_v_bladder = cumsum(v_bladder);
plot(r_bladder, cum_v_bladder);
ovh(:,1)=r_bladder;
ovh(:,2)=v_bladder;



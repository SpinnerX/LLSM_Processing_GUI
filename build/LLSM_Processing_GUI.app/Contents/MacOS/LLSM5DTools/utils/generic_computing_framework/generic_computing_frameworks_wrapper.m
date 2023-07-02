function [is_done_flag] = generic_computing_frameworks_wrapper(inputFullpaths, outputFullpaths, funcStrs, varargin)
% generic computing framework that use a function handle/string as input
% for the computing for integration of all computing schemes, including
% slurm, slurm mcc, and their corresponding single job submission. We will
% integrate more frameworks in the future
% 
% Author Xiongtao Ruan (03/09/2023)


ip = inputParser;
ip.CaseSensitive = false;
ip.addRequired('inputFullpaths', @(x) iscell(x) || ischar(x));
ip.addRequired('outputFullpaths', @(x) iscell(x) || ischar(x));
ip.addRequired('functionStrs', @(x) iscell(x) || ischar(x));
ip.addParameter('clusterType', 'slurm', @ischar);
ip.addParameter('mccMode', false, @islogical);
ip.addParameter('parseCluster', true, @islogical);
ip.addParameter('masterCompute', true, @islogical); % master node participate in the task computing. 
ip.addParameter('jobLogDir', '../job_logs', @ischar);
ip.addParameter('tmpDir', '', @ischar);
ip.addParameter('maxCPUNum', 24, @isnumeric);
ip.addParameter('minCPUNum', 1, @isnumeric);
ip.addParameter('cpusPerTask', 1, @isnumeric);
ip.addParameter('MemPerCPU', 20.9, @isnumeric);
ip.addParameter('MemAllocate', [], @isnumeric);
ip.addParameter('wholeNodeJob', false, @islogical); % allocate a whole node for parallel computing
ip.addParameter('uuid', '', @ischar);
ip.addParameter('GPUJob', false, @islogical);
ip.addParameter('GPUNum', 0, @isnumeric);
ip.addParameter('maxTrialNum', 3, @isnumeric);
ip.addParameter('unitWaitTime', 30, @isnumeric);
ip.addParameter('maxJobNum', inf, @isnumeric); % submit limited number of jobs (pending/running)
ip.addParameter('minTaskJobNum', 1, @isnumeric); % split tasks to this given number workers if fewer, mainly for finishing tasks faster with more workers
ip.addParameter('taskBatchNum', 1, @isnumeric); % aggragate several tasks together
ip.addParameter('minBatchNum', 1, @isnumeric); % minimum batch size
ip.addParameter('paraBatchNum', 1, @isnumeric); % number of parallel task batchs
ip.addParameter('MatlabLaunchStr', 'module load matlab/r2023a; matlab -nodisplay -nosplash -nodesktop -nojvm -r', @ischar);
ip.addParameter('BashLaunchStr', '', @ischar);
ip.addParameter('SlurmParam', '-p abc --qos abc_normal -n1 --mem-per-cpu=21418M', @ischar);
ip.addParameter('SlurmConstraint', '', @ischar);
ip.addParameter('MCRParam', '/usr/local/MATLAB/R2022b', @ischar);
ip.addParameter('MCCMasterStr', '/home/xruan/Projects/XR_Repository/mcc/run_mccMaster.sh', @ischar);
ip.addParameter('jobTimeLimit', 24, @isnumeric); % in hour, [] means no limit
ip.addParameter('language', 'matlab', @ischar); % support matlab, bash
ip.addParameter('GNUparallel', false, @islogical); % support matlab, bash
ip.addParameter('paraJobNum', 1, @isnumeric); % support matlab, bash
ip.addParameter('masterParaFactor', 1, @islogical); % master job parallel job percentage for mcc mode. 
ip.addParameter('ConfigFile', '', @ischar); % cluster configuration file that override the default parameters

ip.parse(inputFullpaths, outputFullpaths, funcStrs, varargin{:});

pr = ip.Results;
ConfigFile = pr.ConfigFile;

persistent ConfigFile_orig confData confModDate;
if ~isempty(ConfigFile)
    if ~exist(ConfigFile, 'file')
        error('The cluster configuration file %s does not exist, please check and provide the right one!', ConfigFile);
    end
    dir_info = dir(ConfigFile);
    conf_date = dir_info.date;
    if ~strcmp(ConfigFile, ConfigFile_orig) || isempty(confData) || isempty(confModDate) || any(confModDate ~= conf_date)
        ConfigFile_orig = ConfigFile;
        confModDate = conf_date;
        fprintf('Set up cluster configuration according to %s...\n', ConfigFile);
        [~, ~, ext] = fileparts(ConfigFile);
        switch ext 
            case '.json'
                fid = fopen(ConfigFile);
                raw = fread(fid);
                fclose(fid);
                str = char(raw');
                confData = jsondecode(str);
            case '.mat'
                a = load(ConfigFile);
                confData = a;
        end
        disp('Cluster configuration:');
        disp(confData);        
    end

    conf_keys = fields(confData);
    for i = 1 : numel(conf_keys)
        pr.(conf_keys{i}) = confData.(conf_keys{i});
    end
end

clusterType = pr.clusterType;
mccMode = pr.mccMode;
parseCluster = pr.parseCluster;
masterCompute = pr.masterCompute;
jobLogDir = pr.jobLogDir;
tmpDir = pr.tmpDir;
maxCPUNum = pr.maxCPUNum;
minCPUNum = pr.minCPUNum;
cpusPerTask = pr.cpusPerTask;
MemPerCPU = pr.MemPerCPU;
MemAllocate = pr.MemAllocate;
wholeNodeJob = pr.wholeNodeJob; 
uuid = pr.uuid;
GPUJob = pr.GPUJob;
GPUNum = pr.GPUNum;
maxTrialNum = pr.maxTrialNum;
unitWaitTime = pr.unitWaitTime;
maxJobNum = pr.maxJobNum;
minTaskJobNum = pr.minTaskJobNum;
taskBatchNum = pr.taskBatchNum;
minBatchNum = pr.minBatchNum;
paraBatchNum = pr.paraBatchNum;
MatlabLaunchStr = pr.MatlabLaunchStr;
BashLaunchStr = pr.BashLaunchStr;
SlurmParam = pr.SlurmParam;
SlurmConstraint = pr.SlurmConstraint;
MCRParam = pr.MCRParam;
MCCMasterStr = pr.MCCMasterStr;
jobTimeLimit = pr.jobTimeLimit;
language = pr.language;
GNUparallel = pr.GNUparallel;
paraJobNum = pr.paraJobNum;
masterParaFactor = pr.masterParaFactor;

if numel(funcStrs) == 1
    if masterCompute
        parseCluster = false;
        mccMode = ismcc || isdeployed;        
    end
end

switch clusterType
    case 'slurm'
        if ~isempty(MemAllocate) && cpusPerTask * MemPerCPU < MemAllocate
            cpusPerTask = min(maxCPUNum, max([minCPUNum, cpusPerTask, ceil(MemAllocate / MemPerCPU)]));
        end
        
        if (ismcc || isdeployed || mccMode) && parseCluster
            % only allow master compute if the job itself is in mcc or deployed mode.
            masterCompute = (ismcc || isdeployed) && masterCompute;

            if wholeNodeJob
                paraJobNum = floor(maxCPUNum / cpusPerTask);
                cpusPerTask = maxCPUNum;
                if GPUJob
                    paraJobNum = min(paraJobNum, GPUNum);
                end                
            end
            taskBatchNum = max(taskBatchNum, minBatchNum);            
            taskBatchNum = ceil(taskBatchNum ./ paraJobNum) * paraJobNum;
            taskBatchNum = max(taskBatchNum, paraJobNum * paraBatchNum);
            if numel(inputFullpaths) / taskBatchNum < (minTaskJobNum / paraJobNum)
                taskBatchNum = max(ceil(numel(inputFullpaths) / minTaskJobNum), 1);
            end

            if wholeNodeJob && GPUJob
                taskBatchNum = ceil(taskBatchNum ./ paraJobNum) * paraJobNum;
            end

            is_done_flag = mcc_slurm_cluster_generic_computing_wrapper(inputFullpaths, ...
                outputFullpaths, funcStrs, parseCluster=parseCluster, masterCompute=masterCompute, ...
                jobLogDir=jobLogDir, tmpDir=tmpDir, maxCPUNum=maxCPUNum, cpusPerTask=cpusPerTask, ...
                uuid=uuid, maxTrialNum=maxTrialNum, unitWaitTime=unitWaitTime, ...
                maxJobNum=maxJobNum, taskBatchNum=taskBatchNum, BashLaunchStr=BashLaunchStr, ...
                SlurmParam=SlurmParam, SlurmConstraint=SlurmConstraint, MCRParam=MCRParam, ...
                MCCMasterStr=MCCMasterStr, jobTimeLimit=jobTimeLimit, language=language, ...
                GNUparallel=GNUparallel, paraJobNum=paraJobNum, masterParaFactor=masterParaFactor, ...
                GPUJob=GPUJob);
        else
            is_done_flag = slurm_cluster_generic_computing_wrapper(inputFullpaths, ...
                outputFullpaths, funcStrs, parseCluster=parseCluster, masterCompute=masterCompute, ...
                jobLogDir=jobLogDir, tmpDir=tmpDir, maxCPUNum=maxCPUNum, cpusPerTask=cpusPerTask, ...
                uuid=uuid, maxTrialNum=maxTrialNum, unitWaitTime=unitWaitTime, ...
                maxJobNum=maxJobNum, taskBatchNum=taskBatchNum, MatlabLaunchStr=MatlabLaunchStr, ...
                BashLaunchStr=BashLaunchStr, SlurmParam=SlurmParam, SlurmConstraint=SlurmConstraint, ...
                jobTimeLimit=jobTimeLimit, language=language);
        end
    case 'parfor'
        is_done_flag= matlab_parfor_generic_computing_wrapper(inputFullpaths, outputFullpaths, ...
            funcStrs, 'maxJobNum', maxJobNum, 'taskBatchNum', taskBatchNum, 'GPUJob', GPUJob, 'uuid', uuid);
end

end


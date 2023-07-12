classdef GriddedReconModel < Reconstruct.Recon.ReconModel.ReconModel
    methods
        % Constructor
        function [obj] = GriddedReconModel(systemModel, verbose)
            % Call super constructor to build recon obj
            obj = obj@Reconstruct.Recon.ReconModel.ReconModel(systemModel, verbose);
        end
        % PJN 2/14/2019 - Add GridVol to pass back k space as well as
        % reconstructed image
        function [reconVol,GridVol] = reconstruct(obj, data, traj)
            if(obj.verbose)
                disp('Reconstructing...');
            end
            
            % Grid data
            if(obj.verbose)
                disp('Gridding Data...');
            end
            reconVol = obj.grid(data);
            if(obj.verbose)
                disp('Finished gridding Data...');
            end
            
            reconVol = reshape(full(reconVol),ceil(obj.system.fullsize));
            %PJN 2/14/2019 I think the above line is the gridded k-space data. I want
            %to be able to see this too, so let's save that here:
            GridVol = reconVol;
            % Reshape from vector to matrix
            if(obj.verbose)
                disp('Calculating IFFTN...');
            end
            % Calculate image space
            reconVol = ifftn(reconVol);
            reconVol = fftshift(reconVol);
            if(obj.verbose)
                disp('Finished calculating IFFTN.');
            end
            
            if(obj.crop)
                reconVol = obj.system.crop(reconVol);
            end
            
            if(obj.deapodize)
                % Calculate deapodization volume and deapodize
                if(obj.verbose)
                    disp('Calculating k-space deapodization function...');
                end
                deapVol = obj.grid(double(~any(traj,2)));
                
                % Reshape from vector to matrix
                deapVol = reshape(full(deapVol),ceil(obj.system.fullsize));
                if(obj.verbose)
                    disp('Finished calculating k-space deapodization function.');
                end
                
                % Calculate image domain representation
                if(obj.verbose)
                    disp('Calculating Image domain deapodization function...');
                end
                deapVol = ifftn(deapVol);
                deapVol = fftshift(deapVol);
                if(obj.verbose)
                    disp('Calculating Image domain deapodization function...');
                end
                
                if(obj.crop)
                    deapVol = obj.system.crop(deapVol);
                end
                
                if(obj.verbose)
                    disp('deapodizing...');
                end
                reconVol = reconVol./deapVol;
                clear deapVol;
                if(obj.verbose)
                    disp('Finished deapodizing.');
                end
            end
            
            if(obj.verbose)
                disp('Finished Reconstructing.');
            end
        end
    end
    methods (Abstract)
        gridVol = grid(obj, data);
    end
end

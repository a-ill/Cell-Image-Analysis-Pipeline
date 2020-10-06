classdef scaleLayer < nnet.layer.Layer

    properties
        % (Optional) Layer properties.

        % Layer properties go here.
        Coeff
    end

    methods
        function layer = scaleLayer(name,coeff)
            % (Optional) Create a myLayer.
            % This function must have the same name as the class.

            % Layer constructor function goes here.
            layer.Name = name;
            layer.Coeff = coeff;
        end
        
        function [Z1] = predict(layer, X1)
            % Forward input data through the layer at prediction time and
            % output the result.
            %
            % Inputs:
            %         layer       - Layer to forward propagate through
            %         X1, ..., Xn - Input data
            % Outputs:
            %         Z1, ..., Zm - Outputs of layer forward function
            
            % Layer forward function for prediction goes here.
            Z1 = zeros([size(X1,1,2)*2,size(X1,3,4)],'like',X1);
            Z1(1:2:end,1:2:end,:,:) = X1(:,:,:,:);
            Z1(2:2:end,2:2:end,:,:) = X1(:,:,:,:);
            Z1(1:2:end,2:2:end,:,:) = X1(:,:,:,:);
            Z1(2:2:end,1:2:end,:,:) = X1(:,:,:,:);
        end
        
       
    end
end
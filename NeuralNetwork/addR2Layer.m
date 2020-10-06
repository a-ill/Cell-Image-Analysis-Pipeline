classdef addR2Layer < nnet.layer.Layer

    properties
        % (Optional) Layer properties.

        % Layer properties go here.
    end

    methods
        function layer = addR2Layer(name)
            % (Optional) Create a myLayer.
            % This function must have the same name as the class.

            % Layer constructor function goes here.
            layer.Name = name;
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
            coeff = size(X1,3)/2;
            Z1 = X1(:,:,1:coeff,:) + X1(:,:,(coeff+1):size(X1,3),:);
        end
        
       
    end
end
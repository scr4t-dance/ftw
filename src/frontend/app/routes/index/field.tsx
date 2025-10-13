import React, { type ReactElement } from "react";

type FieldProps = {
  label?: string;
  htmlFor?: string;
  error?: string;
  children: React.ReactNode;
};


export const Field: React.FC<FieldProps> = ({ label, htmlFor, error, children }) => {
  return (
    <div className="form_subelem">
      {label && <label htmlFor={htmlFor}>{label}</label>}
      {children}
      {error && (
        <div role="alert" className="error_message">
          {error}
        </div>
      )}
    </div>
  );
};


export const RadioField: React.FC<FieldProps> = ({ error, children }) => {
  return (
    <div className="yan_radio">
      {children}
      {error && (
        <div role="alert" className="error_message">
          {error}
        </div>
      )}
    </div>
  );
};
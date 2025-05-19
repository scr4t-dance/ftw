import React, { type ReactElement } from "react";

type FieldProps = {
  label?: string;
  htmlFor?: string;
  error?: string;
  children: ReactElement;
};

export const Field: React.FC<FieldProps> = ({ label, htmlFor, error, children }) => {
  const id = htmlFor || getChildId(children);

  return (
    <div className="form_subelem">
      {label && <label htmlFor={id}>{label}</label>}
      {children}
      {error && (
        <div role="alert" className="error">
          {error}
        </div>
      )}
    </div>
  );
};

function getChildId(child: ReactElement): string | undefined {
  if (React.isValidElement(child) && typeof child.props === "object" && child.props !== null) {
    return (child as ReactElement<{ id?: string }>).props.id;
  }
  return undefined;
}

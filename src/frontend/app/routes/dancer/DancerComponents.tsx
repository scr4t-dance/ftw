import React from 'react';
import { useGetApiDancers, getGetApiDancerIdQueryOptions, useGetApiDancerId } from '@hookgen/dancer/dancer';

import { DivisionsItem, type Dancer, type DancerId, type DancerIdList, type Divisions } from "@hookgen/model";
import { Link, useLocation } from "react-router";
import DancerCompetitionHistory from '@routes/dancer/DancerCompetitionHistory';
import { SaveDancerFormComponent } from '@routes/dancer/NewDancerForm';
import { useQueries } from '@tanstack/react-query';
import { useCombobox } from 'downshift';
import cx from 'classnames'


const divisionColors: Record<DivisionsItem, string> = {
    [DivisionsItem.None]: '#9ca3af',
    [DivisionsItem.Novice]: '#3C1',
    [DivisionsItem.Novice_Intermediate]: '#1BC',
    [DivisionsItem.Intermediate]: '#08C',
    [DivisionsItem.Intermediate_Advanced]: '#94E',
    [DivisionsItem.Advanced]: '#E43',
};

export function Badge({ role, divisions }: { role: string, divisions: Divisions }) {

    // exclude the croisillon # for shields.io service
    const badge_color = divisionColors[divisions[0]].slice(1);

    return (
        <img className="role_badge" alt={`${role}-${divisions}`} src={`https://img.shields.io/badge/${role}-${divisions}-${badge_color}`} />
    );
}

function DancerDetails({ id_dancer, dancer, index }: { id_dancer: DancerId, dancer: Dancer, index: number }) {

    const location = useLocation();
    const url = location.pathname.includes("admin") ? "/admin/dancers/" : "/dancers/";


    return (
        <tr key={id_dancer}
            className={`${index % 2 === 0 ? 'even-row' : 'odd-row'}`}>
            <td>
                <Link to={`${url}${id_dancer}`}>
                    {dancer.last_name}
                </Link>
            </td>
            <td>
                <Link to={`${url}${id_dancer}`}>
                    {dancer.first_name}
                </Link>
            </td>
            <td>
                {dancer.as_follower[0] !== DivisionsItem.None &&
                    <Badge role='F' divisions={dancer.as_follower} />
                }
            </td>
            <td>
                {dancer.as_leader[0] !== DivisionsItem.None &&
                    <Badge role='L' divisions={dancer.as_leader} />
                }
            </td>
        </tr>

    );
}

export function BareDancerListComponent({ dancer_list, dancer_data }: { dancer_list: DancerIdList, dancer_data: Dancer[] }) {

    if (dancer_list.dancers.length != dancer_data.length) return <p>Invalid data for BareDancerListComponent</p>

    return (
        <>
            <h1>Liste Compétiteur-ices</h1>
            <table>
                <tbody>
                    <tr>
                        <th>Nom</th>
                        <th>Prénom</th>
                        <th>Division follower</th>
                        <th>Division leader</th>
                    </tr>

                    {dancer_list?.dancers?.map((dancerId, index) => (
                        <DancerDetails key={dancerId} id_dancer={dancerId} dancer={dancer_data[index]} index={index} />
                    ))}
                </tbody>
            </table>
        </>
    );
}

export function InnerDancerListComponent({ dancer_list }: { dancer_list: DancerIdList }) {

    const dancerDataQueries = useQueries({
        queries: dancer_list.dancers.map((dancerId) => ({
            ...getGetApiDancerIdQueryOptions(dancerId),
            enabled: true,
        })),
    });

    const isLoading = dancerDataQueries.some((query) => query.isLoading);
    const isError = dancerDataQueries.some((query) => query.isError);


    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (isError) return (
        <div>
            Error loading judges data
            {
                dancerDataQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);

    const dancer_data = dancerDataQueries.map((query) => query.data as Dancer);

    return (
        <>
            <BareDancerListComponent dancer_list={dancer_list as DancerIdList} dancer_data={dancer_data} />
        </>
    );
}


export function DancerListComponent() {

    const { data: dancer_list, isLoading, isError, error } = useGetApiDancers();

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (isError) return <div>Erreur: {(error as any).message}</div>;

    return (
        <>
            <InnerDancerListComponent dancer_list={dancer_list as DancerIdList} />
        </>
    );
}


export function DancerPageComponent({ id_dancer }: { id_dancer: DancerId }) {


    const { data: dancer, isLoading, isError, error, isSuccess} = useGetApiDancerId(id_dancer);

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (isError) return <div>Erreur: {error.message}</div>;
    if (!isSuccess) return <div>Erreur Chargement</div>;

    return (
        <>
            <DancerPagePublicComponent id_dancer={id_dancer} />
            <p>Birthday: "Hidden"</p>
            <p>Email : "Hidden"</p>
            <h1>Mise à jour données</h1>
            <SaveDancerFormComponent id_dancer={id_dancer} dancer={dancer} />

        </>
    );
}

export function DancerPagePublicComponent({ id_dancer }: { id_dancer: DancerId }) {

    const { data: dancer, isLoading, isError, error, isSuccess} = useGetApiDancerId(id_dancer);

    if (isLoading) return <div>Chargement des compétiteur-euses...</div>;
    if (isError) return <div>Erreur: {error.message}</div>;
    if (!isSuccess) return <div>Erreur Chargement</div>;

    return (
        <>
            <h1 className="dancer_name">{dancer.first_name}, {dancer.last_name}</h1>
            <DancerCompetitionHistory />
        </>
    );
}

// Dancer Search bar

type DancerWithId = Dancer & { id_dancer: number, prefix: string };

function dancerWithIdToString(dancerWithId: DancerWithId) {
    return dancerWithId.prefix.concat(
        " ", dancerWithId.first_name,
        " ", dancerWithId.last_name,
        " ", dancerWithId.id_dancer.toString(),
    );
}

export function newDancerWithId(dancerIdArray: DancerId[], dancerArray: Dancer[], id_dancer: DancerId, prefix: string): DancerWithId {

    const dancerTargetArray = dancerArray.map((d, index) => ({ ...d, id_dancer: dancerIdArray[index] })).find((d) => d.id_dancer === id_dancer);

    return {
        ...dancerTargetArray,
        prefix: prefix,
    } as DancerWithId;

}

function getDancerWithIdFilter(inputValue: string) {
    const lowerCasedInputValue = inputValue.toLowerCase()

    return function bibFilter(dancerData: DancerWithId) {
        return (
            !inputValue ||
            dancerData.first_name.toLowerCase().includes(lowerCasedInputValue) ||
            dancerData.last_name.toLowerCase().includes(lowerCasedInputValue) ||
            dancerData.id_dancer.toString().includes(lowerCasedInputValue) ||
            dancerData.prefix.toString().includes(lowerCasedInputValue) ||
            dancerWithIdToString(dancerData).toLowerCase().includes(lowerCasedInputValue)
        );
    }
}

type DancerComboboxProps = {
    bibNameList: DancerWithId[],
    selectedItem: DancerWithId | null,
    onChangeItem: (d: DancerId | null) => void,
    label?: string,
    error?: string
}

export function DancerComboBox({ bibNameList, selectedItem, onChangeItem, label, error }: DancerComboboxProps) {

    const [items, setItems] = React.useState(bibNameList)
    const {
        isOpen,
        getToggleButtonProps,
        getLabelProps,
        getMenuProps,
        getInputProps,
        highlightedIndex,
        getItemProps,
        reset,
    } = useCombobox({
        onInputValueChange({ inputValue }) {
            setItems(bibNameList.filter(getDancerWithIdFilter(inputValue)))
        },
        items,
        itemToString(item: DancerWithId | null) {
            return item ? dancerWithIdToString(item) : ''
        },
        selectedItem,
        onSelectedItemChange: ({ selectedItem: newSelectedItem }) =>
            onChangeItem(newSelectedItem?.id_dancer ?? null),
    })

    return (
        <div className="form_subelem">
            <div className="w-72 flex flex-col gap-1">
                <label className="w-fit" {...getLabelProps()}>
                    {label ? label : ""}
                </label>
                <div className="flex shadow-sm bg-white gap-0.5">
                    <input
                        placeholder="Default Dancer"
                        className="w-full p-1.5"
                        {...getInputProps()}
                    />
                    <button
                        aria-label="toggle menu"
                        className="px-2"
                        type="button"
                        {...getToggleButtonProps()}
                    >
                        {isOpen ? <>&#8593;</> : <>&#8595;</>}
                    </button>
                </div>
            </div>
            <ul
                className={`absolute w-72 bg-white mt-1 shadow-md max-h-80 overflow-scroll p-0 z-10 ${!(isOpen && items.length) && 'hidden'
                    }`}
                {...getMenuProps()}
            >
                {isOpen &&
                    items.map((item, index) => (
                        <li
                            className={cx(
                                highlightedIndex === index && 'bg-blue-300',
                                selectedItem === item && 'font-bold',
                                'py-2 px-3 shadow-sm flex flex-col',
                            )}
                            key={item.id_dancer}
                            {...getItemProps({ item, index })}
                        >
                            <span>{item.prefix} {item.first_name} {item.last_name} </span>
                            <span className="text-sm text-gray-700">{item.id_dancer}</span>
                        </li>
                    ))}
            </ul>

            <button
                onClick={() => {
                    reset()
                }}
            >
                Reset
            </button>
            {error && (
                <div role="alert" className="error_message">
                    {error}
                </div>
            )}
        </div>
    )
}

type DancerComboBoxComponentProps = {
    dancerIdList: DancerIdList,
    selectedItem: DancerId | null,
    onChangeItem: (d: DancerId | null) => void,
    label?: string,
    error?: string,
    prefixArray?: string[]
}

export function DancerComboBoxComponent({ dancerIdList, selectedItem, onChangeItem, label, error, prefixArray }: DancerComboBoxComponentProps) {

    const idDancerArray = [...new Set(dancerIdList.dancers)];

    const dancerQueries = useQueries({
        queries: idDancerArray.map((id_dancer) => ({
            ...getGetApiDancerIdQueryOptions(id_dancer),
        })),
    });

    const isDancersLoading = dancerQueries.some((query) => query.isLoading);
    const isDancersError = dancerQueries.some((query) => query.isError);
    const isDancerSuccess = dancerQueries.some((query) => query.isSuccess);

    if (isDancersLoading) return <div>Loading dancers details...</div>;
    if (isDancersError) return (
        <div>
            Error loading dancer data
            {
                dancerQueries.map((query) => {
                    return (<p>{query.error?.message}</p>);
                })
            }
        </div>);
    if (!isDancerSuccess) {
        return (<p>Unsuccessful queries</p>);
    }

    const dancerData = dancerIdList.dancers.map((id_dancer, index) => {
        const indexData = idDancerArray.findIndex((id_d) => id_dancer === id_d);

        return {
            ...(dancerQueries[indexData].data as Dancer),
            id_dancer: id_dancer,
            prefix: prefixArray ? prefixArray[index] : "",
        } as DancerWithId;
    })

    return (
        <>
            <DancerComboBox bibNameList={dancerData}
                selectedItem={dancerData.find((d) => d.id_dancer === selectedItem) ?? null}
                onChangeItem={onChangeItem}
                label={label} error={error}
            />
        </>
    )
}
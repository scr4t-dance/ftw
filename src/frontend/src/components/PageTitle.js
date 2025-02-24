import {useEffect} from 'react';

function PageTitle(title) {
    useEffect(() => {
        document.title = title.title;
    }, [title]);

    return null;
}

export default PageTitle;
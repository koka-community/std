import fs from 'fs';

function readfile(f) {
    return new Promise((resolve, reject) => {
        return fs.readFile(f, 'utf8', (err, data) => {
            if (err) {
              reject(err);
            }
            resolve(data);
        });
    });
}


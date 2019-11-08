# ALTENLAB-OCR
ALTENLAB-OCR is a text recognition platform that built with Vue.js. Its goal is to recognize text online from files in
format PNG, JPEG, PDF and Tiff through the method of optical character recognition (OCR). The core libraries used in this
project are Tesseract.js, PDF.js and Tiff.js.
The users can also obtain the information they want through selecting the related options. Since the main need is
to recognize invoices of clients, the current available options are id, HT, TTC, TVA, etc.

## Getting Started
### Online demo
[https://remy1604.github.io/altenlab/](https://remy1604.github.io/altenlab/)


## Getting Code
To get a local copy of the current code, clone it using git:
```
$ git clone https://github.com/remy1604/altenlab.git
```

## Project setup
```
npm install
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Run your tests
```
npm run test
```

### Lints and fixes files
```
npm run lint
```

### Save your code change
```
$ git add.
$ git commit -m <COMMIT NAME>
$ git pull origin master
$ git push origin master
```

### Deploy application automatically
```
$ bash deploy.sh
```

### Attention
1. The uploaded files should not be over 50MB.
2. Vertical recognition is not supported currently.
3. The current supported file formats are png, jpg, and pdf.

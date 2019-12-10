<template>
  <div class="app">
    <div v-if="showOverlayer" class="overlayer">
      <div class="loader"></div>
    </div>
    <h1>AltenLab-OCR platform</h1>
    <div class="container">
      <div class="container--step">
        <h3>STEP 1 - Upload file</h3>
        <input type="file" @change="upload"/>
        <p>Supported formats: jpg, png, pdf, tiff</p>
        <p>Max file size: 50MB</p>
      </div>

      <div class="container--step">
        <h3>STEP 2 - Select your information</h3>
        <select v-model="selected">
          <option disabled value="">Select file type</option>
          <option value="default">Default</option>
          <option value="invoice">Invoice</option>
        </select>
        <!--selector for invoice-->
        <div v-if="selected === 'invoice' && text" class="container-checkbox">
          <div class="checkbox">
            <input type="checkbox" v-model="options" value="page"><span>Page quantity</span>
          </div>
          <div class="checkox">
            <input type="checkbox" v-model="options" value="id"><span>Invoice number</span>
          </div>
          <div class="checkox">
            <input type="checkbox" v-model="options" value="ttc"><span>TTC</span>
          </div>
          <div class="checkox">
            <input type="checkbox" v-model="options" value="ht"><span>HT</span>
          </div>
          <div class="checkox">
            <input type="checkbox" v-model="options" value="tva"><span>TVA</span>
          </div>
          <div class="checkox">
            <input type="checkbox" v-model="options" value="date"><span>Date</span>
          </div>
          <div class="checkox">
            <input type="checkbox" v-model="options" value="address"><span>Address</span>
          </div>
        </div>
        <div class="checkbox" v-if="selected === 'default' && text">
          <input type="checkbox" v-model="options" value="page"><span>Page quantity</span>
        </div>
      </div>

      <div class="container--step">
        <h3>STEP 3 - Find your information here</h3>
        <p v-if="seconds > 0">This identification took {{seconds}} seconds.</p>
        <p>Find below all the possible results according to your choices in step 2</p>
      </div>
    </div>

    <div class="container">
      <div class="container--step">
        <div v-show="text" class="card-round">
          <p>Uploaded File :</p>
          <div id="imgDiv"></div>
        </div>
      </div>
      <div class="container--step">
        <div v-if="text" class="card-round">
          <p>Recognized Text:</p>
          <div class="card-round" v-for="(element, index) in textArr" :key="index">{{element}}</div>
        </div>
      </div>
      <div class="container--step">
        <div class="card-round" v-for="element in options" :key="element">
          <span v-if="element === 'page'">Page : {{invoice.page}}</span>
          <p v-if="element === 'id'">Invoice number result:</p>
          <p v-if="element === 'ttc'">TTC result :</p>
          <p v-if="element === 'ht'">HT result :</p>
          <p v-if="element === 'tva'">TVA result :</p>
          <p v-if="element === 'date'">Date result :</p>
          <p v-if="element === 'address'">Address result :</p>
          <ul v-if="element !== 'page'">
            <li v-for="(result,index) in invoice[element]" :key="index">{{result}}</li>
          </ul>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
  /* eslint-disable */
  import { createWorker, PSM, OEM } from 'tesseract.js';
  const worker = createWorker({
    logger: m => {}
  });

  import PDFJS from 'pdfjs-dist';
  PDFJS.GlobalWorkerOptions.workerSrc = 'pdfjs-dist/build/pdf.worker.js';

  import Tiff from 'tiff.js';

  export default {
    name: 'app',
    data() {
      return {
        selected: '',
        file: 0,
        showOverlayer: false,
        text: '',
        textArr: [],
        invoice: {
          page: 1,
          id: [],
          ttc: [],
          ht: [],
          tva: [],
          date: [],
          address: []
        },
        options: [],
        seconds: 0
      }
    },
    watch: {
      options() {
        if(this.options != null) {
          this.options.forEach(element => {
            if(element != 'page') {
              this.invoice[element] = this.matchInfo(element)
            }
          })
        }
      }
    },
    mounted() {
       this.load();
    },
    methods: {
      async load() {
        await worker.load();
        await worker.loadLanguage('eng+fra');
        await worker.initialize('fra', OEM.LSTM_ONLY);
        await worker.setParameters({
          tessedit_pageseg_mode: PSM.SINGLE_BLOCK,
        });
      },
      upload(e) {
        if(this.file > 0) {
          this.refresh();
          this.recognizeFile(e)
        }else {
          this.file ++;
          this.recognizeFile(e)
        }
      },
      refresh() {
        //clear the recognized text
        this.text = '';
        this.textArr = [];

        //clear time
        this.seconds = 0;

        //clear options
        this.options = [];

        //clear all <img/>
        const imgDiv = document.getElementById('imgDiv');
        while(imgDiv.hasChildNodes()) {
          imgDiv.removeChild(imgDiv.firstChild)
        }
      },
      recognizeFile(e) {
        const file = e.target.files[0];
        if(file.size <= 50000000) {
          //if format is pdf
          this.showOverlayer = true;
          var time = setInterval(()=> {
            this.seconds++
          }, 1000);
          if(file.type.indexOf('pdf')>-1) {
            this.recognizePdf(file, time);
          }else if(file.type.indexOf('tif')>-1 || file.type.indexOf('tiff')>-1) {
            this.recognizeTiff(file, time)
          }
          else {
            this.recognizeImage(file, time);
          }
        }else {
          alert ('The uploaded file should not be over 50MB!')
        }
      },
      recognizeTiff(file, time) {
        var reader = new FileReader();
        reader.readAsArrayBuffer(file);
        reader.addEventListener("load",  () => {
          var tiff = new Tiff({buffer: reader.result});
          var pageNum = tiff.countDirectory();
          this.invoice.page = pageNum;
          for (var i = 0; i < pageNum; ++i) {
            tiff.setDirectory(i);
            //tiff to canvas
            var canvas = tiff.toCanvas();
            canvas.style.width = "100%";
            canvas.style.height = "100%";
            canvas.style.boxShadow = '0px 0px 5px #888888';
            const imageDiv = document.getElementById('imgDiv');
            imageDiv.append(canvas);
          }
          this.recognizeCanvas(time)
        })
      },
      recognizePdf(file, time) {
        var reader = new FileReader();
        reader.readAsArrayBuffer(file);
        reader.addEventListener("load",  () => {
          PDFJS.getDocument(reader.result).then((pdf) => {
            var pageNum = pdf.numPages;
            this.invoice.page = pageNum;
            const imageDiv = document.getElementById('imgDiv');
            for(var i = 1; i <= pageNum; i++) {
              //generate blank canvas
              var canvas = document.createElement('canvas');
              canvas.id = "pageNum" + i;
              imageDiv.append(canvas);
              const context = canvas.getContext('2d');
              this.canvas2Text(pdf, i, pageNum, context, time);
            }
          })
        }, false)
      },
      canvas2Text(pdf, i, pageNum, context, time) {
        var scale = 2;
        //pdf to canvas
        pdf.getPage(i).then((page) => {
          var viewport = page.getViewport(scale); // reference canvas via context
          var canvasObj = context.canvas;
          canvasObj.width = viewport.width;
          canvasObj.height = viewport.height;
          canvasObj.style.width = "100%";
          canvasObj.style.height = "100%";
          canvasObj.style.boxShadow = '0px 0px 5px #888888';
          var renderContext = {
            canvasContext: context,
            viewport: viewport
          };
          page.render(renderContext).then(() => {
            if(i == pageNum) {
              this.recognizeCanvas(time);
            }
          });
        })
      },
      async recognizeCanvas(time) {
        // recognize canvas
        var canvasArr = document.getElementsByTagName('canvas');
        for(let i=0; i<canvasArr.length; i++) {
          const {data: { text }} = await worker.recognize(canvasArr[i]);
          this.text += text;
          this.textArr.push(text);
        }
        this.showOverlayer = false;
        clearInterval(time)
      },
      recognizeImage(file, time) {
        var imageDiv = document.getElementById('imgDiv');
        var reader = new FileReader();
        reader.readAsDataURL(file);
        reader.addEventListener("load", () => {
          const img = document.createElement('img');
          img.src = reader.result;
          img.style.width = '100%';
          img.style.height = '100%';
          img.style.boxShadow = '0px 0px 5px #888888';
          imageDiv.append(img);
          this.recognizeImg(time)
        }, false);
      },
      async recognizeImg(time) {
        var imgArr = document.getElementsByTagName('img');
        const {data: { text }} = await worker.recognize(imgArr[0]);
        this.text += text;
        this.textArr.push(text);
        this.showOverlayer = false
        clearInterval(time)
      },
      matchInfo(val) {
        var result = [];
        switch(val) {
          case('id'):
            var idReg = /(facture|n\W\s)(.*)\d+\s/gi;
            result = this.matchKeyWords(idReg);
            break;
          case('ht'):
            var htReg = /(ht|(h\.t\.*))\s(.*)\d+/gi;
            result = this.matchKeyWords(htReg);
            break;
          case('ttc'):
            var ttcReg = /(ttc|t\.t\.c\.*)\s(.*)\d+/gi;
            result = this.matchKeyWords(ttcReg);
            break;
          case('tva'):
            var tvaReg = /(tva|t\.v\.a\.*)\s(.*)\d+/gi;
            result = this.matchKeyWords(tvaReg);
            break;
          case('date'):
            result = this.matchDates();
            break;
          case('address'):
            result = this.matchAddress();
            break;
          default:
        }
        return result
      },
      matchKeyWords(reg) {
        var textCache = this.text;
        return textCache.match(reg);
      },
      matchDates() {
        var textCache = this.text;

        //match dates with month name
        var regMonth = /janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre/gi;
        var monthArr = textCache.match(regMonth);
        var result = [];
        var regFront;
        var regBack;
        if(monthArr != null) {
          for(let i=0; i<monthArr.length; i++){
            regFront = new RegExp('(.*)'+ monthArr[i], "gi");
            regBack = new RegExp(monthArr[i] + '(.*)', "gi");
            let front = textCache.match(regFront)[0];
            let back = textCache.match(regBack)[0];
            let option = front.replace(monthArr[i], '').slice(-6) + monthArr[i] + back.replace(monthArr[i], '').slice(0, 5);
            result.push(option);
            textCache = textCache.replace(option, '');
          }
        }

        //match dates like 'DD/MM/YYYY' or 'DD/MM/YY'
        var regDayMonthYear = /(\d{2})(\/|-)(\d{2})(\/|-)(\d{4}|\d{2})/gi;
        var dmyArr = textCache.match(regDayMonthYear);
        result = dmyArr != null ? result.concat(dmyArr) : result;

        //match dates like 'DD/YYYY'
        var regMonthYear = /(\d{2})\/(\d{4})/gi;
        var myArr = textCache.match(regMonthYear);
        result = myArr != null ? result.concat(myArr) : result;
        return result;
      },
      matchAddress() {
        var textCache = this.text;
        var result = [];
        var addressArr1 = [];
        var addressArr2 = [];
        //adress format: 01 rue xxx (xxx) (xxx) (xxx) 75000 xxx (xxx)
        var regAddress1 = /(\d+\S*)\s(rue|r|avenue|av|boulevard|bd|chemin|ch|route|PROMENADE)(.*)(\d+)\s([a-zA-ZàâäèéêëîïôœùûüÿçÀÂÄÈÉÊËÎÏÔŒÙÛÜŸÇ]+)\s([a-zA-ZàâäèéêëîïôœùûüÿçÀÂÄÈÉÊËÎÏÔŒÙÛÜŸÇ]*)/gi;
        addressArr1 = textCache.match(regAddress1);

        //adress format: 01 rue xxx (xxx)
        var regAddress2 = /(\d+\S*)\s(rue|r|avenue|av|boulevard|bd|chemin|ch|route|PROMENADE)\s([a-zA-ZàâäèéêëîïôœùûüÿçÀÂÄÈÉÊËÎÏÔŒÙÛÜŸÇ]+)([\sa-zA-ZàâäèéêëîïôœùûüÿçÀÂÄÈÉÊËÎÏÔŒÙÛÜŸÇ]*)/gi;
        addressArr2 = textCache.match(regAddress2);

        return result.concat(addressArr1, addressArr2)
      }
    }
  }
</script>

<style>
  .app {
    font-family: 'Avenir', Helvetica, Arial, sans-serif;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    text-align: center;
    color: #2c3e50;
  }
  .overlayer {
    width: 100%;
    height: 100vh;
    overflow: hidden;
    z-index: 99;
    background-color: rgba(0, 0, 0, 0.7);
    position: fixed;
    left: 0;
    top: 0;
    display: flex;
    justify-content: center;
    align-items: center;
  }
  .loader {
    border: 16px solid #f3f3f3; /* Light grey */
    border-top: 16px solid #3498db; /* Blue */
    border-radius: 50%;
    width: 120px;
    height: 120px;
    animation: spin 2s linear infinite;
  }

  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
  .container {
    display: flex;
    justify-content: center;
    width: 100%;
    height: 100%;
    overflow: auto;
  }
  .container--step {
    margin: 20px;
    width: 33%;
  }
  .container-checkbox {
    display: flex;
    flex-direction: column;
    align-items: start;
    padding-left: 30%
  }
  .card-round {
    margin: 15px;
    padding: 5px;
    box-shadow: 0 0 5px #888888;
    border-radius: 10px;
  }
</style>

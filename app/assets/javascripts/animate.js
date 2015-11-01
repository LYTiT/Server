$(window).load(function() {

    //Social icon bouncing
    $(".twitter").hover(function () {
        $(this).toggleClass("animated bounce");
    });
    $(".facebook").hover(function () {
        $(this).toggleClass("animated bounce");
    });



    //LYTs' Map positiong
    var features = [
    {
        x: 1300 ,
        y: 1025,
        name: "01"//New York
    }, {
        x: 1140,
        y: 1428,
        name: "02"//Miami
    }, {
        x: 970,
        y: 1020,
        name: "03"//Chicago
    }, {
        x: 750,
        y: 1240,
        name: "04"//Dallas
    }, {
        x: 577,
        y: 1050,
        name: "05"//Denver
    }, {
        x: 150,
        y: 1120,
        name: "06"//San Francisco
    }, {
        x: 160,
        y: 830,
        name: "07"//Seattle
    }, {
        x: 660,
        y: 1620,
        name: "08"//Mexico City
    }, {
        x: 1470,
        y: 1865,
        name: "09"//Caracas
    }, {
        x: 3020,
        y: 660,
        name: "10"//London
    }, {
        x: 2970,
        y: 1050,
        name: "11"//Madrid
    }, {
        x: 3440,
        y: 380,
        name: "12"//Stockholm
    }, {
        x: 3340,
        y: 1000,
        name: "13"//Rome
    }, {
        x: 3350,
        y: 620,
        name: "14"//Berlin
    }, {
        x: 3660,
        y: 900,
        name: "15"//Bucharest
    }, {
        x: 4026,
        y: 438,
        name: "16"//Moscow
    }, {
        x: 4330,
        y: 1490,
        name: "17"//Dubai
    }, {
        x: 3780,
        y: 1350,
        name: "18"//Cairo
    }, {
        x: 3280,
        y: 1170,
        name: "19"//Tunis
    }, {
        x: 2865,
        y: 1260,
        name: "20"//Casa Blanca
    }, {
        x: 3260,
        y: 1690,
        name: "21"//Agadez
    }, {
        x: 3525,
        y: 640,
        name: "22"//Warsaw
    }, {
        x: 340,
        y: 1180,
        name: "23"//Las Vegas
    }, {
        x: 1040,
        y: 1250,
        name: "24"//Atlanta
    }, {
        x: 1350,
        y: 850,
        name: "25"//Quebec
    }, {
        x: 3110,
        y: 790,
        name: "26"//Paris
    }, {
        x: 3760,
        y: 1150,
        name: "27"//Anatalya
    }, {
        x: 3770,
        y: 710,
        name: "28"//Kiev
    }, {
        x: 3110,
        y: 1180,
        name: "29"//Algiers
    }
    ];

    //elem:     element that has the bg image
    //features: array of features to mark on the image
    //bgWidth:  intrinsic width of background image
    //bgHeight: intrinsic height of background image
    function FeatureImage(elem, features, bgWidth, bgHeight) {
        this.ratio = bgWidth / bgHeight; //aspect ratio of bg image
        this.element = elem;
        this.features = features;
        var feature, p;
        for (var i = 0; i < features.length; i++) {
            feature = features[i];
            if (matchMedia('only screen and (min-width:1400px)').matches) {
                feature.left = (feature.x+30) / bgWidth; //percent from the left edge of bg image the feature resides with slight adjustment for bigger screens
                feature.bottom = (bgHeight - feature.y+30) / bgHeight; //percent from bottom edge of bg image that feature resides               
            } else{
                feature.left = feature.x / bgWidth; //percent from the left edge of bg image the feature resides
                feature.bottom = (bgHeight - feature.y) / bgHeight; //percent from bottom edge of bg image that feature resides               
            }
            
            feature.p = this.createMarker(feature.name);
        }
        window.addEventListener("resize", this.setFeaturePositions.bind(this));
        this.setFeaturePositions(); //initialize the <p> positions
    }

    FeatureImage.prototype.createMarker = function (name) {
        var div = document.createElement("div"); //the <div> that acts as the feature marker
        div.className = "lyt".concat(name)
        div.innerHTML = name;
        this.element.appendChild(div);
        return div
    }

    FeatureImage.prototype.setFeaturePositions = function () {
        var eratio = this.element.clientWidth / this.element.clientHeight; //calc the current container aspect ratio
        if (eratio > this.ratio) { // width of scaled bg image is equal to width of container
            this.scaledHeight = this.element.clientWidth / this.ratio; // pre calc the scaled height of bg image
            this.scaledDY = (this.scaledHeight - this.element.clientHeight) / 2; // pre calc the amount of the image that is outside the bottom of the container
            this.features.forEach(this.setWide, this); // set the position of each feature marker
        } else { // height of scaled bg image is equal to height of container
            this.scaledWidth = this.element.clientHeight * this.ratio; // pre calc the scaled width of bg image
            this.scaledDX = (this.scaledWidth - this.element.clientWidth) / 2; // pre calc the amount of the image that is outside the left of the container
            this.features.forEach(this.setTall, this); // set the position of each feature marker
        }
    }

    FeatureImage.prototype.setWide = function (feature) {
        feature.p.style.left = feature.left * this.element.clientWidth + "px";
        feature.p.style.bottom = this.scaledHeight * feature.bottom - this.scaledDY + "px"; // calc the pixels above the bottom edge of the image - the amount below the container
    }

    FeatureImage.prototype.setTall = function (feature) {
        feature.p.style.bottom = feature.bottom * this.element.clientHeight + "px";
        feature.p.style.left = this.scaledWidth * feature.left - this.scaledDX + "px"; // calc the pixels to the right of the left edge of image - the amount left of the container
    }

    var x = new FeatureImage(document.getElementsByClassName("header")[0], features, 4555, 2336);

    //Animating LYT dropping
    function drop_lyt01(){
       $('.lyt01').css('visibility', 'visible').toggleClass("animated zoomIn");
    }
    function drop_lyt02(){
       $('.lyt02').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt03(){
       $('.lyt03').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt04(){
       $('.lyt04').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt05(){
       $('.lyt05').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt06(){
       $('.lyt06').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt07(){
       $('.lyt07').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt08(){
       $('.lyt08').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt09(){
       $('.lyt09').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt10(){
       $('.lyt10').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }    
    function drop_lyt11(){
       $('.lyt11').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt12(){
       $('.lyt12').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt13(){
       $('.lyt13').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt14(){
       $('.lyt14').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt15(){
       $('.lyt15').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt16(){
       $('.lyt16').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt17(){
       $('.lyt17').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt18(){
       $('.lyt18').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt19(){
       $('.lyt19').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt20(){
       $('.lyt20').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt21(){
       $('.lyt21').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt22(){
       $('.lyt22').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt23(){
       $('.lyt23').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt24(){
       $('.lyt24').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt25(){
       $('.lyt25').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt26(){
       $('.lyt26').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt27(){
       $('.lyt27').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt28(){
       $('.lyt28').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }
    function drop_lyt29(){
       $('.lyt29').css('visibility', 'visible').toggleClass("animated zoomIn"); 
    }

    $(".header-top").ready(function(){
        $(".lyt01").ready(function(){
            t1 = setTimeout(drop_lyt01, 0000);
        });
        $(".lyt02").ready(function(){
            t2 = setTimeout(drop_lyt02, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt03").ready(function(){
            t3 = setTimeout(drop_lyt03, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt04").ready(function(){
            t4 = setTimeout(drop_lyt04, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt05").ready(function(){
            t5 = setTimeout(drop_lyt05, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt06").ready(function(){
            t6 = setTimeout(drop_lyt06, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt07").ready(function(){
            t7 = setTimeout(drop_lyt07, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt08").ready(function(){
            t8 = setTimeout(drop_lyt08, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt09").ready(function(){
            t9 = setTimeout(drop_lyt09, Math.floor((Math.random() * 10) + 1)*250);
        });  
        $(".lyt10").ready(function(){
            t10 = setTimeout(drop_lyt10, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt11").ready(function(){
            t11 = setTimeout(drop_lyt11, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt12").ready(function(){
            t12 = setTimeout(drop_lyt12, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt13").ready(function(){
            t13 = setTimeout(drop_lyt13, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt14").ready(function(){
            t14 = setTimeout(drop_lyt14, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt15").ready(function(){
            t15 = setTimeout(drop_lyt15, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt16").ready(function(){
            t16 = setTimeout(drop_lyt16, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt17").ready(function(){
            t17 = setTimeout(drop_lyt17, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt18").ready(function(){
            t18 = setTimeout(drop_lyt18, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt19").ready(function(){
            t19 = setTimeout(drop_lyt19, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt20").ready(function(){
            t20 = setTimeout(drop_lyt20, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt21").ready(function(){
            t21 = setTimeout(drop_lyt21, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt22").ready(function(){
            t22 = setTimeout(drop_lyt22, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt23").ready(function(){
            t23 = setTimeout(drop_lyt23, Math.floor((Math.random() * 10) + 1)*250);
        });    
        $(".lyt24").ready(function(){
            t24 = setTimeout(drop_lyt24, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt25").ready(function(){
            t25 = setTimeout(drop_lyt25, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt26").ready(function(){
            t26 = setTimeout(drop_lyt26, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt27").ready(function(){
            t27 = setTimeout(drop_lyt27, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt28").ready(function(){
            t28 = setTimeout(drop_lyt28, Math.floor((Math.random() * 10) + 1)*250);
        });
        $(".lyt29").ready(function(){
            t29 = setTimeout(drop_lyt29, Math.floor((Math.random() * 10) + 1)*250);
        });
    });

    if (matchMedia('only screen and (max-width:767px)').matches) {
        $(".feature-box.invert-mobile").each(function() {
            var $this = $(this);
            var div1 = $this.find('.rightPadding');
            var div2 = $this.find('.leftPadding');

            var tdiv1 = div1.clone();
            var tdiv2 = div2.clone();

            if(!div2.is(':empty')){
                div1.replaceWith(tdiv2);
                div2.replaceWith(tdiv1);
            }
        });
    }
    $(window).scroll(function() {

        var y = $(this).scrollTop();
         setTimeout(function () {
        }, 5000);

        if (matchMedia('only screen and (max-width:416px)').matches) {
            if(y >= 1) {
                $( ".right-map" ).hide(0);
                $('#moment01').css('visibility', 'visible').addClass('animated zoomInUp');
                $('#moment02').css('visibility', 'visible').addClass('animated zoomInUp');
                $(".left-map").css({
                    "float": "left",
                    "margin-left": "6%"
                });
                 $(".right-map").css({
                    "float": "left",
                    "margin-left": "6%",
                    "margin-bottom": "60px",
                    "margin-top": "70px"
                });
            }
        } else  if (matchMedia('only screen and (max-width:767px)').matches) {
            if(y >= 1) {
                $( ".right-map" ).hide(0);
                $('#moment01').css('visibility', 'visible').addClass('animated zoomInUp');
                $('#moment03').css('visibility', 'visible').addClass('animated zoomInUp');
                $(".left-map").css({
                    "float": "left",
                    "margin-left": "30%"
                });
                 $(".right-map").css({
                    "float": "left",
                    "margin-left": "10%",
                    "margin-bottom": "73px",
                    "margin-top": "70px"
                });
            }
        } else {
            if(y >= 800) {
                $('#moment02').css('visibility', 'visible').addClass('animated zoomInUp');
                setTimeout(function () {
                    $('#moment01').css('visibility', 'visible').addClass('animated zoomInUp');
                }, 200);
                setTimeout(function () {
                    $('#moment03').css('visibility', 'visible').addClass('animated zoomInUp');
                }, 300);
            }
        }

    });
});
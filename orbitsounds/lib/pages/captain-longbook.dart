import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:heroicons/heroicons.dart';
import 'package:geolocator/geolocator.dart';

import '../services/weather_service.dart';
import '../models/weather_model.dart';

class Longbook extends StatefulWidget {
  const Longbook({super.key});

  @override
  State<Longbook> createState() => _LongbookState();
}

class Emotion {
  final String name;
  final String svg;
  final double top; // posición Y (40 = arriba, 79 = abajo)

  Emotion({required this.name, required this.svg, required this.top});
}

final List<String> _albumCovers = [
  "assets/images/Kamui.jpg",
  "assets/images/Kamui.jpg",
  "assets/images/Kamui.jpg",
  "assets/images/Kamui.jpg",
  "assets/images/Kamui.jpg",
];


// Lista de emociones activas (puedes probar cambiando aquí)
final List<String> _selectedEmotions = ["joy","sadness","anger","fear","love","boredom","embarrasment","anxiety","disgust","envy"];

// Mapa de emociones disponibles
final List<Emotion> _allEmotions = [
  Emotion(
    name: "joy",
    top: 40, // arriba
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M0 25.3521L3.32872 26.7166C6.65745 28.536 14.4245 31.7198 21.0819 30.3553C27.7394 28.536 35.5064 22.1682 42.1638 21.2585C48.8213 20.3488 56.5883 25.3521 63.2457 24.4424C69.9032 23.5327 76.5606 17.1649 84.3276 18.5294C90.9851 20.3488 97.6425 30.3553 105.41 32.6295C112.067 34.9037 118.724 30.3553 126.491 30.3553C133.149 30.3553 139.806 34.9037 147.573 36.7231C154.231 38.5425 160.888 36.7231 168.655 30.8102C175.313 25.3521 181.97 15.3455 189.737 14.4359C196.395 13.981 203.052 22.1682 209.71 21.2585C217.477 20.3488 224.134 10.3423 230.791 12.1616C238.558 13.981 245.216 26.7166 251.873 26.2617C259.64 25.3521 266.298 10.3423 272.955 6.2487C280.722 2.15512 287.38 8.97775 294.037 14.4359C301.804 20.3488 308.462 25.3521 315.119 26.7166C322.886 28.536 329.544 26.7166 336.201 28.536C342.858 30.3553 350.625 34.9037 357.283 36.7231C363.94 38.5425 371.707 36.7231 378.365 33.5392C385.022 30.3553 392.789 25.3521 396.118 22.623L399.447 20.3488V44.9103H396.118C392.789 44.9103 385.022 44.9103 378.365 44.9103C371.707 44.9103 363.94 44.9103 357.283 44.9103C350.625 44.9103 342.858 44.9103 336.201 44.9103C329.544 44.9103 322.886 44.9103 315.119 44.9103C308.462 44.9103 301.804 44.9103 294.037 44.9103C287.38 44.9103 280.722 44.9103 272.955 44.9103C266.298 44.9103 259.64 44.9103 251.873 44.9103C245.216 44.9103 238.558 44.9103 230.791 44.9103C224.134 44.9103 217.477 44.9103 209.71 44.9103C203.052 44.9103 196.395 44.9103 189.737 44.9103C181.97 44.9103 175.313 44.9103 168.655 44.9103C160.888 44.9103 154.231 44.9103 147.573 44.9103C139.806 44.9103 133.149 44.9103 126.491 44.9103C118.724 44.9103 112.067 44.9103 105.41 44.9103C97.6425 44.9103 90.9851 44.9103 84.3276 44.9103C76.5606 44.9103 69.9032 44.9103 63.2457 44.9103C56.5883 44.9103 48.8213 44.9103 42.1638 44.9103C35.5064 44.9103 27.7394 44.9103 21.0819 44.9103C14.4245 44.9103 6.65745 44.9103 3.32872 44.9103H0V25.3521Z" fill="#FECA39" fill-opacity="0.54"/>
</svg>
    ''',
  ),
  Emotion(
    name: "sadness",
    top: 40, // arriba
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M399.447 25.3521L396.119 26.7166C392.79 28.536 385.023 31.7198 378.365 30.3553C371.708 28.536 363.941 22.1682 357.283 21.2585C350.626 20.3488 342.859 25.3521 336.202 24.4424C329.544 23.5327 322.887 17.1649 315.12 18.5294C308.462 20.3488 301.805 30.3553 294.038 32.6295C287.38 34.9037 280.723 30.3553 272.956 30.3553C266.298 30.3553 259.641 34.9037 251.874 36.7231C245.216 38.5425 238.559 36.7231 230.792 30.8102C224.135 25.3521 217.477 15.3455 209.71 14.4359C203.053 13.981 196.395 22.1682 189.738 21.2585C181.971 20.3488 175.313 10.3423 168.656 12.1616C160.889 13.981 154.231 26.7166 147.574 26.2617C139.807 25.3521 133.149 10.3423 126.492 6.2487C118.725 2.15512 112.068 8.97775 105.41 14.4359C97.6431 20.3488 90.9856 25.3521 84.3282 26.7166C76.5612 28.536 69.9037 26.7166 63.2463 28.536C56.5888 30.3553 48.8218 34.9037 42.1644 36.7231C35.5069 38.5425 27.7399 36.7231 21.0825 33.5392C14.425 30.3553 6.658 25.3521 3.32928 22.623L0.000554085 20.3488V44.9103H3.32928C6.658 44.9103 14.425 44.9103 21.0825 44.9103C27.7399 44.9103 35.5069 44.9103 42.1644 44.9103C48.8218 44.9103 56.5888 44.9103 63.2463 44.9103C69.9037 44.9103 76.5612 44.9103 84.3282 44.9103C90.9856 44.9103 97.6431 44.9103 105.41 44.9103C112.068 44.9103 118.725 44.9103 126.492 44.9103C133.149 44.9103 139.807 44.9103 147.574 44.9103C154.231 44.9103 160.889 44.9103 168.656 44.9103C175.313 44.9103 181.971 44.9103 189.738 44.9103C196.395 44.9103 203.053 44.9103 209.71 44.9103C217.477 44.9103 224.135 44.9103 230.792 44.9103C238.559 44.9103 245.216 44.9103 251.874 44.9103C259.641 44.9103 266.298 44.9103 272.956 44.9103C280.723 44.9103 287.38 44.9103 294.038 44.9103C301.805 44.9103 308.462 44.9103 315.12 44.9103C322.887 44.9103 329.544 44.9103 336.202 44.9103C342.859 44.9103 350.626 44.9103 357.283 44.9103C363.941 44.9103 371.708 44.9103 378.365 44.9103C385.023 44.9103 392.79 44.9103 396.119 44.9103H399.447V25.3521Z" fill="#2390D3" fill-opacity="0.68"/>
</svg>
    ''',
  ),
  Emotion(
    name: "fear",
    top: 40, // arriba
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M0.555176 29.5393L3.8839 30.6179C8.27158 33.4616 25.8127 42.0611 34.952 36.7303C41.6094 33.4944 47.1573 25.5842 52.7052 20.5505C58.253 15.1572 63.8009 12.6403 70.4584 14.0785C76.0062 15.1572 81.5541 20.5505 87.102 25.5842C99.7171 37.0302 97.15 35.5251 122.608 32.7753C128.156 32.0561 133.704 34.573 139.252 36.7303C144.8 38.5281 151.457 39.9663 157.005 36.0112C163.562 31.3365 170.043 6.07866 191.679 5.35959C213.316 4.64053 237.172 29.6294 241.055 27.2922C244.939 24.9551 250.764 12.3708 264.911 14.0785C279.058 15.7863 290.154 28.1011 295.702 28.8202C301.25 29.5393 307.907 21.6291 313.455 22.3482C335.072 25.1502 337.455 32.3336 365.605 33.8539C371.153 34.573 376.701 32.0561 382.249 32.7753C388.906 33.4944 394.454 37.0899 396.673 39.2472L400.002 41.0449V45H396.673C394.454 45 388.906 45 382.249 45C376.701 45 371.153 45 365.605 45C358.948 45 353.4 45 347.852 45C342.304 45 336.756 45 330.099 45C324.551 45 319.003 45 313.455 45C307.907 45 301.25 45 295.702 45C290.154 45 284.606 45 277.949 45C272.401 45 266.853 45 261.305 45C255.757 45 249.1 45 243.552 45C238.004 45 232.456 45 225.799 45C220.251 45 214.703 45 209.155 45C203.607 45 196.95 45 191.402 45C185.854 45 180.306 45 174.758 45C168.101 45 162.553 45 157.005 45C151.457 45 144.8 45 139.252 45C133.704 45 128.156 45 122.608 45C115.951 45 110.403 45 104.855 45C99.3073 45 92.6498 45 87.102 45C81.5541 45 76.0062 45 70.4584 45C63.8009 45 58.253 45 52.7052 45C47.1573 45 41.6094 45 34.952 45C29.4041 45 23.8562 45 18.3084 45C11.6509 45 6.10305 45 3.8839 45H0.555176V29.5393Z" fill="#944FBC" fill-opacity="0.59"/>
</svg>
    ''',
  ),
  Emotion(
    name: "disgust",
    top: 40, // arriba
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M0.277832 39.7236L3.60655 40.0855C7.99424 41.0394 25.5354 43.9244 34.6746 42.136C41.3321 41.0504 46.8799 38.3968 52.4278 36.7081C57.9757 34.8988 63.5236 34.0545 70.181 34.537C75.7289 34.8988 81.2767 36.7081 86.8246 38.3968C99.4397 42.2366 96.8727 41.7317 122.331 40.8092C127.879 40.568 133.427 41.4123 138.975 42.136C144.522 42.7391 151.18 43.2216 156.728 41.8948C163.285 40.3265 169.765 31.8532 191.402 31.612C213.039 31.3708 236.895 39.7538 240.778 38.9698C244.662 38.1857 250.487 33.9641 264.634 34.537C278.781 35.1099 289.877 39.2411 295.425 39.4824C300.972 39.7236 307.63 37.07 313.178 37.3112C334.795 38.2512 337.178 40.6611 365.328 41.1711C370.876 41.4123 376.423 40.568 381.971 40.8092C388.629 41.0504 394.177 42.2566 396.396 42.9804L399.725 43.5835V44.9103H396.396C394.177 44.9103 388.629 44.9103 381.971 44.9103C376.423 44.9103 370.876 44.9103 365.328 44.9103C358.67 44.9103 353.122 44.9103 347.575 44.9103C342.027 44.9103 336.479 44.9103 329.821 44.9103C324.273 44.9103 318.726 44.9103 313.178 44.9103C307.63 44.9103 300.972 44.9103 295.425 44.9103C289.877 44.9103 284.329 44.9103 277.672 44.9103C272.124 44.9103 266.576 44.9103 261.028 44.9103C255.48 44.9103 248.823 44.9103 243.275 44.9103C237.727 44.9103 232.179 44.9103 225.522 44.9103C219.974 44.9103 214.426 44.9103 208.878 44.9103C203.33 44.9103 196.673 44.9103 191.125 44.9103C185.577 44.9103 180.029 44.9103 174.481 44.9103C167.824 44.9103 162.276 44.9103 156.728 44.9103C151.18 44.9103 144.522 44.9103 138.975 44.9103C133.427 44.9103 127.879 44.9103 122.331 44.9103C115.674 44.9103 110.126 44.9103 104.578 44.9103C99.0301 44.9103 92.3726 44.9103 86.8246 44.9103C81.5541 44.9103 76.0062 44.9103 70.181 44.9103C63.5236 44.9103 57.9757 44.9103 52.4278 44.9103C46.8799 44.9103 41.3321 44.9103 34.6746 44.9103C29.1267 44.9103 23.5788 44.9103 18.031 44.9103C11.3735 44.9103 5.82562 44.9103 3.60655 44.9103H0.277832V39.7236Z" fill="#91C836" fill-opacity="0.62"/>
</svg>
    ''',
  ),
  Emotion(
    name: "boredom",
    top: 40, // arriba
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M0 40.3267L3.32872 40.9298C6.65745 42.1557 14.4245 44.6075 21.0819 44.0043C27.7394 42.1557 35.5064 36.8365 42.1638 36.2333C48.8213 35.6301 56.5883 40.3267 63.2457 39.7236C69.9032 39.1204 76.5606 33.8012 84.3276 34.4044C90.9851 35.6301 97.6425 44.6075 105.41 45H126.491H147.573H168.655H189.737H209.71H230.791H251.873H272.955H294.037H315.119H336.201H357.283H378.365H399.447V40.3267L396.118 40.9298C392.789 42.1557 385.022 44.6075 378.365 44.0043C371.707 42.1557 363.94 36.8365 357.283 36.2333C350.625 35.6301 342.858 40.3267 336.201 39.7236C329.544 39.1204 322.886 33.8012 315.119 34.4044C308.462 35.6301 301.804 44.6075 294.037 45H272.955H251.873H230.791H209.71H189.737H168.655H147.573H126.491H105.41H84.3276H63.2457H42.1638H21.0819H3.32872H0V40.3267Z" fill="#A08888" fill-opacity="0.62"/>
</svg>
    ''',
  ),
  Emotion(
    name: "anger",
    top: 79, // abajo
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M2 22.104L5.31207 20.5689C8.62413 18.5221 16.3523 14.9402 22.9764 16.4753C29.6006 18.5221 37.3287 25.6858 43.9528 26.7092C50.577 27.7326 58.3051 22.104 64.9293 23.1273C71.5534 24.1507 78.1775 31.3145 85.9057 29.7794C92.5298 27.7326 99.154 16.4753 106.882 13.9168C113.506 11.3583 120.13 16.4753 127.859 16.4753C134.483 16.4753 141.107 11.3583 148.835 9.31152C155.459 7.26473 162.083 9.31152 169.811 15.9636C176.436 22.104 183.06 33.3613 190.788 34.3847C197.412 34.8964 204.036 25.6858 210.66 26.7092C218.388 27.7326 225.012 38.99 231.637 36.9432C239.365 34.8964 245.989 20.5689 252.613 21.0806C260.341 22.104 266.965 38.99 273.589 43.5952C281.318 48.2005 287.942 40.5251 294.566 34.3847C302.294 27.7326 308.918 22.104 315.542 20.5689C323.27 18.5221 329.895 20.5689 336.519 18.5221C343.143 16.4753 350.871 11.3583 357.495 9.31152C364.119 7.26473 371.847 9.31152 378.472 12.8934C385.096 16.4753 392.824 22.104 396.136 25.1741L399.448 27.7326V0.100964H396.136C392.824 0.100964 385.096 0.100964 378.472 0.100964C371.847 0.100964 364.119 0.100964 357.495 0.100964C350.871 0.100964 343.143 0.100964 336.519 0.100964C329.895 0.100964 323.27 0.100964 315.542 0.100964C308.918 0.100964 302.294 0.100964 294.566 0.100964C287.942 0.100964 281.318 0.100964 273.589 0.100964C266.965 0.100964 260.341 0.100964 252.613 0.100964C245.989 0.100964 239.365 0.100964 231.637 0.100964C225.012 0.100964 218.388 0.100964 210.66 0.100964C204.036 0.100964 197.412 0.100964 190.788 0.100964C183.06 0.100964 176.436 0.100964 169.811 0.100964C162.083 0.100964 155.459 0.100964 148.835 0.100964C141.107 0.100964 134.483 0.100964 127.859 0.100964C120.13 0.100964 113.506 0.100964 106.882 0.100964C99.154 0.100964 92.5298 0.100964 85.9057 0.100964C78.1775 0.100964 71.5534 0.100964 64.9293 0.100964C58.3051 0.100964 50.577 0.100964 43.9528 0.100964C37.3287 0.100964 29.6006 0.100964 22.9764 0.100964C16.3523 0.100964 8.62413 0.100964 5.31207 0.100964H2V22.104Z" fill="#FF595D" fill-opacity="0.24"/>
</svg>
    ''',
  ),
  Emotion(
    name: "love",
    top: 79, // abajo
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M399.448 22.104L396.136 20.5689C392.824 18.5221 385.096 14.9402 378.472 16.4753C371.848 18.5221 364.12 25.6859 357.495 26.7093C350.871 27.7327 343.143 22.104 336.519 23.1274C329.895 24.1508 323.271 31.3146 315.543 29.7795C308.918 27.7327 302.294 16.4753 294.566 13.9169C287.942 11.3584 281.318 16.4753 273.59 16.4753C266.966 16.4753 260.341 11.3584 252.613 9.31158C245.989 7.26479 239.365 9.31158 231.637 15.9636C225.013 22.104 218.389 33.3614 210.66 34.3847C204.036 34.8964 197.412 25.6859 190.788 26.7093C183.06 27.7327 176.436 38.99 169.812 36.9432C162.083 34.8964 155.459 20.5689 148.835 21.0806C141.107 22.104 134.483 38.99 127.859 43.5953C120.131 48.2006 113.506 40.5251 106.882 34.3847C99.1542 27.7327 92.5301 22.104 85.9059 20.5689C78.1778 18.5221 71.5536 20.5689 64.9295 18.5221C58.3054 16.4753 50.5772 11.3584 43.9531 9.31158C37.3289 7.26479 29.6008 9.31158 22.9766 12.8935C16.3525 16.4753 8.62436 22.104 5.31229 25.1742L2.00023 27.7327V0.101025H5.31229C8.62436 0.101025 16.3525 0.101025 22.9766 0.101025C29.6008 0.101025 37.3289 0.101025 43.9531 0.101025C50.5772 0.101025 58.3054 0.101025 64.9295 0.101025C71.5536 0.101025 78.1778 0.101025 85.9059 0.101025C92.5301 0.101025 99.1542 0.101025 106.882 0.101025C113.506 0.101025 120.131 0.101025 127.859 0.101025C134.483 0.101025 141.107 0.101025 148.835 0.101025C155.459 0.101025 162.083 0.101025 169.812 0.101025C176.436 0.101025 183.06 0.101025 190.788 0.101025C197.412 0.101025 204.036 0.101025 210.66 0.101025C218.389 0.101025 225.013 0.101025 231.637 0.101025C239.365 0.101025 245.989 0.101025 252.613 0.101025C260.341 0.101025 266.966 0.101025 273.59 0.101025C281.318 0.101025 287.942 0.101025 294.566 0.101025C302.294 0.101025 308.918 0.101025 315.543 0.101025C323.271 0.101025 329.895 0.101025 336.519 0.101025C343.143 0.101025 350.871 0.101025 357.495 0.101025C364.12 0.101025 371.848 0.101025 378.472 0.101025C385.096 0.101025 392.824 0.101025 396.136 0.101025H399.448V22.104Z" fill="#B53E8E" fill-opacity="0.55"/>
</svg>
    ''',
  ),
  Emotion(
    name: "anxiety",
    top: 79, // abajo
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M399.447 15.4607L396.118 14.3821C391.73 11.5384 374.189 2.93892 365.05 8.26968C358.393 11.5056 352.845 19.4158 347.297 24.4495C341.749 29.8428 336.201 32.3597 329.544 30.9215C323.996 29.8428 318.448 24.4495 312.9 19.4158C300.285 7.96976 302.852 9.47487 277.394 12.2247C271.846 12.9439 266.298 10.427 260.75 8.26968C255.202 6.47192 248.545 5.03371 242.997 8.98878C236.439 13.6635 229.959 38.9213 208.323 39.6404C186.686 40.3595 162.83 15.3706 158.947 17.7078C155.063 20.0449 149.238 32.6292 135.091 30.9215C120.944 29.2137 109.848 16.8989 104.3 16.1798C98.7522 15.4607 92.0947 23.3709 86.5469 22.6518C64.9297 19.8498 62.5465 12.6664 34.3969 11.1461C28.849 10.427 23.3011 12.9439 17.7533 12.2247C11.0958 11.5056 5.54794 7.91013 3.32879 5.75282L6.58035e-05 3.95506V-1.41887e-05H3.32879C5.54794 -1.41887e-05 11.0958 -1.41887e-05 17.7533 -1.41887e-05C23.3011 -1.41887e-05 28.849 -1.41887e-05 34.3969 -1.41887e-05C41.0543 -1.41887e-05 46.6022 -1.41887e-05 52.1501 -1.41887e-05C57.6979 -1.41887e-05 63.2458 -1.41887e-05 69.9032 -1.41887e-05C75.4511 -1.41887e-05 80.999 -1.41887e-05 86.5469 -1.41887e-05C92.0947 -1.41887e-05 98.7522 -1.41887e-05 104.3 -1.41887e-05C109.848 -1.41887e-05 115.396 -1.41887e-05 122.053 -1.41887e-05C127.601 -1.41887e-05 133.149 -1.41887e-05 138.697 -1.41887e-05C144.245 -1.41887e-05 150.902 -1.41887e-05 156.45 -1.41887e-05C161.998 -1.41887e-05 167.546 -1.41887e-05 174.203 -1.41887e-05C179.751 -1.41887e-05 185.299 -1.41887e-05 190.847 -1.41887e-05C196.395 -1.41887e-05 203.052 -1.41887e-05 208.6 -1.41887e-05C214.148 -1.41887e-05 219.696 -1.41887e-05 225.244 -1.41887e-05C231.901 -1.41887e-05 237.449 -1.41887e-05 242.997 -1.41887e-05C248.545 -1.41887e-05 255.202 -1.41887e-05 260.75 -1.41887e-05C266.298 -1.41887e-05 271.846 -1.41887e-05 277.394 -1.41887e-05C284.051 -1.41887e-05 289.599 -1.41887e-05 295.147 -1.41887e-05C300.695 -1.41887e-05 307.352 -1.41887e-05 312.9 -1.41887e-05C318.448 -1.41887e-05 323.996 -1.41887e-05 329.544 -1.41887e-05C336.201 -1.41887e-05 341.749 -1.41887e-05 347.297 -1.41887e-05C352.845 -1.41887e-05 358.393 -1.41887e-05 365.05 -1.41887e-05C370.598 -1.41887e-05 376.146 -1.41887e-05 381.694 -1.41887e-05C388.351 -1.41887e-05 393.899 -1.41887e-05 396.118 -1.41887e-05H399.447V15.4607Z" fill="#FF924D" fill-opacity="0.59"/>
</svg>
    ''',
  ),
  Emotion(
    name: "embarrassment",
    top: 79, // abajo
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M2.55176 17.3934L5.86382 16.1799C10.2296 12.9808 27.6829 3.30637 36.7764 9.30347C43.4006 12.9439 48.9207 21.8429 54.4408 27.5058C59.9609 33.5732 65.481 36.4047 72.1052 34.7867C77.6253 33.5732 83.1454 27.5058 88.6655 21.8429C101.217 8.96606 98.6633 10.6593 123.994 13.7529C129.514 14.5619 135.034 11.7304 140.555 9.30347C146.075 7.28099 152.699 5.66301 158.219 10.1125C164.743 15.3715 171.191 43.7866 192.72 44.5956C214.248 45.4045 237.984 17.2921 241.849 19.9213C245.713 22.5506 251.509 36.7079 265.585 34.7867C279.661 32.8655 290.702 19.0114 296.222 18.2024C301.742 17.3934 308.366 26.2923 313.886 25.4833C335.395 22.3311 337.766 14.2498 365.775 12.5394C371.295 11.7304 376.815 14.5619 382.335 13.7529C388.96 12.9439 394.48 8.89898 396.688 6.472L400 4.44952V6.10352e-05H396.688C394.48 6.10352e-05 388.96 6.10352e-05 382.335 6.10352e-05C376.815 6.10352e-05 371.295 6.10352e-05 365.775 6.10352e-05C359.151 6.10352e-05 353.631 6.10352e-05 348.111 6.10352e-05C342.591 6.10352e-05 337.07 6.10352e-05 330.446 6.10352e-05C324.926 6.10352e-05 319.406 6.10352e-05 313.886 6.10352e-05C308.366 6.10352e-05 301.742 6.10352e-05 296.222 6.10352e-05C290.702 6.10352e-05 285.181 6.10352e-05 278.557 6.10352e-05C273.037 6.10352e-05 267.517 6.10352e-05 261.997 6.10352e-05C256.477 6.10352e-05 249.853 6.10352e-05 244.333 6.10352e-05C238.813 6.10352e-05 233.292 6.10352e-05 226.668 6.10352e-05C221.148 6.10352e-05 215.628 6.10352e-05 210.108 6.10352e-05C204.588 6.10352e-05 197.964 6.10352e-05 192.444 6.10352e-05C186.923 6.10352e-05 181.403 6.10352e-05 175.883 6.10352e-05C169.259 6.10352e-05 163.739 6.10352e-05 158.219 6.10352e-05C152.699 6.10352e-05 146.075 6.10352e-05 140.555 6.10352e-05C135.034 6.10352e-05 129.514 6.10352e-05 123.994 6.10352e-05C117.37 6.10352e-05 111.85 6.10352e-05 106.33 6.10352e-05C100.81 6.10352e-05 94.1856 6.10352e-05 88.6655 6.10352e-05C83.1454 6.10352e-05 77.6253 6.10352e-05 72.1052 6.10352e-05C65.481 6.10352e-05 59.9609 6.10352e-05 54.4408 6.10352e-05C48.9207 6.10352e-05 43.4006 6.10352e-05 36.7764 6.10352e-05C31.2563 6.10352e-05 25.7362 6.10352e-05 20.2161 6.10352e-05C13.592 6.10352e-05 8.07187 6.10352e-05 5.86382 6.10352e-05H2.55176V17.3934Z" fill="#B53F5F" fill-opacity="0.51"/>
</svg>
    ''',
  ),
  Emotion(
    name: "envy",
    top: 79, // abajo
    svg: '''
<svg width="380" height="45" viewBox="0 0 400 45" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M1 5.18665L4.32872 4.82479C8.71641 3.87083 26.2575 0.985923 35.3968 2.77425C42.0542 3.85983 47.6021 6.51347 53.15 8.20215C58.6979 10.0115 64.2457 10.8558 70.9032 10.3733C76.451 10.0115 81.9989 8.20216 87.5468 6.51347C100.162 2.67364 97.5948 3.17856 123.053 4.10107C128.601 4.34231 134.149 3.49797 139.697 2.77425C145.245 2.17115 151.902 1.68867 157.45 3.01549C164.007 4.58374 170.487 13.0571 192.124 13.2983C213.761 13.5395 237.617 5.15643 241.5 5.94048C245.384 6.72453 251.209 10.9462 265.356 10.3733C279.503 9.80042 290.599 5.66913 296.147 5.42789C301.695 5.18665 308.352 7.84029 313.9 7.59905C335.517 6.65907 337.9 4.24923 366.05 3.73921C371.598 3.49797 377.146 4.34231 382.694 4.10107C389.351 3.85983 394.899 2.65363 397.118 1.92991L400.447 1.32681V-1.25766e-05H397.118C394.899 -1.25766e-05 389.351 -1.25766e-05 382.694 -1.25766e-05C377.146 -1.25766e-05 371.598 -1.25766e-05 366.05 -1.25766e-05C359.392 -1.25766e-05 353.845 -1.25766e-05 348.297 -1.25766e-05C342.749 -1.25766e-05 337.201 -1.25766e-05 330.544 -1.25766e-05C324.996 -1.25766e-05 319.448 -1.25766e-05 313.9 -1.25766e-05C308.352 -1.25766e-05 301.695 -1.25766e-05 296.147 -1.25766e-05C290.599 -1.25766e-05 285.051 -1.25766e-05 278.394 -1.25766e-05C272.846 -1.25766e-05 267.298 -1.25766e-05 261.75 -1.25766e-05C256.202 -1.25766e-05 249.545 -1.25766e-05 243.997 -1.25766e-05C238.449 -1.25766e-05 232.901 -1.25766e-05 226.244 -1.25766e-05C220.696 -1.25766e-05 215.148 -1.25766e-05 209.6 -1.25766e-05C204.052 -1.25766e-05 197.395 -1.25766e-05 191.847 -1.25766e-05C186.299 -1.25766e-05 180.751 -1.25766e-05 175.203 -1.25766e-05C168.546 -1.25766e-05 162.998 -1.25766e-05 157.45 -1.25766e-05C151.902 -1.25766e-05 145.245 -1.25766e-05 139.697 -1.25766e-05C134.149 -1.25766e-05 128.601 -1.25766e-05 123.053 -1.25766e-05C116.396 -1.25766e-05 110.848 -1.25766e-05 105.3 -1.25766e-05C99.7521 -1.25766e-05 93.0947 -1.25766e-05 87.5468 -1.25766e-05C81.9989 -1.25766e-05 76.451 -1.25766e-05 70.9032 -1.25766e-05C64.2457 -1.25766e-05 58.6979 -1.25766e-05 53.15 -1.25766e-05C47.6021 -1.25766e-05 42.0542 -1.25766e-05 35.3968 -1.25766e-05C29.8489 -1.25766e-05 24.3011 -1.25766e-05 18.7532 -1.25766e-05C12.0957 -1.25766e-05 6.54787 -1.25766e-05 4.32872 -1.25766e-05H1V5.18665Z" fill="#34C985" fill-opacity="0.38"/>
</svg>
    ''',
  ),
];



class _LongbookState extends State<Longbook> {
  Future<Weather?>? _weatherFuture;

  // === Notas de voz ===
  final List<String> _voiceNotes = []; // rutas locales de audios grabados
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isRecording = false; // estado grabando o no

  // === Estado de las notas ===
  bool _isEditing = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _getWeatherWithLocation();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
    await Permission.microphone.request();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _notesController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _getWeatherWithLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _weatherFuture = Future.value(null);
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _weatherFuture = Future.value(null);
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _weatherFuture = Future.value(null);
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _weatherFuture =
          WeatherService().fetchWeather(position.latitude, position.longitude);
    });
  }

  // === Funciones de grabación ===
  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/note_${DateTime.now().millisecondsSinceEpoch}.aac';

    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stopRecorder();
    if (path != null) {
      setState(() {
        _voiceNotes.add(path);
        _isRecording = false;
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _playVoiceNotes() async {
    if (_voiceNotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No tienes notas de voz guardadas")),
      );
      return;
    }

    for (final path in _voiceNotes) {
      await _audioPlayer.play(DeviceFileSource(path));
      await _audioPlayer.onPlayerComplete.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = DateFormat('HH').format(now);
    final minute = DateFormat('mm').format(now);
    final weekday = DateFormat('EEEE').format(now);
    final date = DateFormat('d MMMM yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFF010B19),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                // === BLOQUE 1 ===
                SizedBox(
                  width: 412,
                  height: 442,
                  child: Stack(
                    children: [
                      // Fondo con imagen opaca
                      Opacity(
                        opacity: 0.4,
                        child: Image.asset(
                          "assets/images/Jay.jpg",
                          width: 412,
                          height: 332,
                          fit: BoxFit.cover,
                        ),
                      ),

                      // SVG decorativo
                      SvgPicture.string(
                        '''
<svg width="412" height="442" viewBox="0 0 412 440" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="81" y="401.071" width="10" height="10" transform="rotate(-45 81 401.071)" fill="#D9D9D9"/>
<path d="M88 349V389" stroke="#E9E8EE" stroke-width="2"/>
<path d="M88 414V448" stroke="#E9E8EE" stroke-width="2"/>
<rect x="206" y="459" width="10" height="10" transform="rotate(45 206 459)" fill="#D9D9D9"/>
<path d="M406 466H221" stroke="#E9E8EE" stroke-width="2"/>
<path d="M191 466H6.00001" stroke="#E9E8EE" stroke-width="2"/>
</svg>
                        ''',
                        allowDrawingOutsideViewBox: true,
                      ),

                      // Hora
                      Positioned(
                        left: 6,
                        top: 333,
                        child: Container(
                          width: 58,
                          height: 98,
                          color: const Color(0xFF010B19),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(hour,
                                  style: const TextStyle(
                                      color: Color(0XFFE9E8EE),
                                      fontFamily: 'EncodeSansExpanded',
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold)),
                              Text(minute,
                                  style: const TextStyle(
                                      color: Color(0XFFB4B1B8),
                                      fontFamily: 'EncodeSansExpanded',
                                      fontSize: 34,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      // Día
                      Positioned(
                        left: 85,
                        top: 333,
                        child: Container(
                          width: 137,
                          height: 42,
                          alignment: Alignment.center,
                          child: Text(
                            weekday,
                            style: const TextStyle(
                              color: Color(0XFFE9E8EE),
                              fontFamily: 'EncodeSansExpanded',
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),

                      // Fecha
                      Positioned(
                        left: 85,
                        top: 375,
                        child: Container(
                          width: 130,
                          height: 16,
                          alignment: Alignment.center,
                          child: Text(
                            date,
                            style: const TextStyle(
                              color: Color(0XFFB4B1B8),
                              fontSize: 10,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                      ),

                      // === Temperatura ===
                      Positioned(
                        left: 85,
                        top: 395,
                        child: FutureBuilder<Weather?>(
                          future: _weatherFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 129,
                                height: 33,
                                child: Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            } else if (!snapshot.hasData ||
                                snapshot.data == null) {
                              return const SizedBox(width: 129, height: 33);
                            } else {
                              final weather = snapshot.data!;
                              final temp = weather.temperature.round();
                              return Container(
                                width: 129,
                                height: 33,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF010B19),
                                  borderRadius: BorderRadius.circular(16.5),
                                  border: Border.all(
                                      color: const Color(0xFFB4B1B8)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "$temp°C",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'RobotoMono',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      // Botones
                      Positioned(
                        left: 6,
                        top: 30,
                        child: IconButton(
                          icon: const HeroIcon(HeroIcons.arrowLeftCircle,
                              color: Color(0XFFE9E8EE),
                              size: 50,
                              style: HeroIconStyle.outline),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Positioned(
                        left: 300,
                        top: 30,
                        child: IconButton(
                          icon: const HeroIcon(HeroIcons.folderOpen,
                              color: Color(0XFFE9E8EE),
                              size: 50,
                              style: HeroIconStyle.outline),
                          onPressed: () {
                            debugPrint("Heart action");
                          },
                        ),
                      ),
                      Positioned(
                        left: 240,
                        top: 330,
                        child: IconButton(
                          icon: const HeroIcon(HeroIcons.pencilSquare,
                              color: Color(0XFFE9E8EE),
                              size: 50,
                              style: HeroIconStyle.outline),
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                            });
                          },
                        ),
                      ),
                      Positioned(
                        left: 300,
                        top: 330,
                        child: IconButton(
                          icon: HeroIcon(
                            _isRecording
                                ? HeroIcons.stopCircle
                                : HeroIcons.microphone,
                            color: const Color(0XFFE9E8EE),
                            size: 50,
                            style: HeroIconStyle.outline,
                          ),
                          onPressed: _toggleRecording,
                        ),
                      ),
                    ],
                  ),
                ),

                // === BLOQUE 2: Notes + Notas ===
                const SizedBox(height: 0),
                SizedBox(
                  width: 402,
                  height: 124, // altura total del bloque
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // 🔹 alinear arriba
                    children: [
                      // Rectángulo azul con texto vertical "Notes"
                      Container(
                        width: 32,
                        height: 68, // 🔹 altura más chica
                        color: const Color(0xFF010B19).withOpacity(0.93),
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Center(
                            child: Text(
                              "Notes",
                              style: const TextStyle(
                                color: Color(0XFFE9E8EE),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                fontFamily: 'EncodeSansExpanded',
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Rectángulo morado con notas
                      Expanded(
                        child: Container(
                          height: 124, // 🔹 altura completa
                          color: const Color(0xFF010B19),
                          padding: const EdgeInsets.all(8),
                          child: _isEditing
                              ? TextField(
                                  controller: _notesController,
                                  style: const TextStyle(
                                      color: Color(0xFFB4B1B8),
                                      fontFamily: 'RobotoMono'),
                                  maxLines: null,
                                  expands: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: "Escribe tus notas...",
                                    hintStyle:
                                        TextStyle(color: Color(0xFFB4B1B8),
                                        fontFamily: 'RobotoMono'),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Text(
                                    _notesController.text.isEmpty
                                        ? "Sin notas..."
                                        : _notesController.text,
                                    style: const TextStyle(
                                        color: Color(0xFFB4B1B8),
                                        fontFamily: 'RobotoMono'),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                // === BLOQUE 3: Tape + reproducir audios ===
                const SizedBox(height: 0),
                GestureDetector(
                  onTap: _playVoiceNotes, // 🎵 ahora todo el bloque reacciona
                  child: SizedBox(
                    width: 400,
                    height: 40,
                    child: Stack(
                      children: [
                        SvgPicture.string(
                          '''
                <svg width="400" height="40" viewBox="0 0 400 40" fill="none" xmlns="http://www.w3.org/2000/svg">
                <rect x="69" y="4" width="313" height="32" fill="#010B19"/>
                <rect x="0.5" y="0.5" width="399" height="39" rx="19.5" stroke="#B4B1B8"/>
                </svg>
                          ''',
                          allowDrawingOutsideViewBox: true,
                        ),
                        Positioned(
                          left: 16,
                          top: 0,
                          child: Image.asset(
                            "assets/images/tape.png",
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const Positioned(
                          left: 80,
                          top: 6,
                          child: Text(
                            "Listen to your audios",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0XFFE9E8EE),
                              fontFamily: 'RobotoMono'
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


                // === BLOQUE 4: Ondas dinámicas según emociones ===
                const SizedBox(height: 0),
                Stack(
                  children: [
                    // Fondo con rectángulos
                    SvgPicture.string(
                      '''
                <svg width="410" height="150" viewBox="0 0 410 150" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect x="6" y="39" width="398" height="90" rx="15" fill="#010B19" stroke="#B4B1B8" stroke-width="3"/>
                  <rect width="410" height="32" fill="#010B19"/>
                  <rect x="6" y="132" width="398" height="18" fill="#010B19"/>
                </svg>
                      ''',
                      allowDrawingOutsideViewBox: true,
                    ),

                    // Texto en el rectángulo aguamarina
                    const Positioned(
                      top: 5,
                      left: 0,
                      right: 0,
                      height: 32,
                      child: Center(
                        child: Text(
                          "Your emotions today",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0XFFE9E8EE),
                            fontFamily: 'EncodeSansExpanded',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // Texto en el rectángulo morado (emociones seleccionadas con scroll horizontal)
                    Positioned(
                      bottom: 9,
                      left: 6,
                      right: 6,
                      height: 18,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Center(
                          child: Text(
                            _selectedEmotions
                                .map((e) => e[0].toUpperCase() + e.substring(1)) // Mayúscula inicial
                                .join("   "), // separadas con espacios
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE9E8EE),
                              fontFamily: 'RobotoMono',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    // Render dinámico de ondas
                    ..._allEmotions.where((e) => _selectedEmotions.contains(e.name)).map((emotion) {
                      return Positioned(
                        left: 6,
                        top: emotion.top,
                        child: SizedBox(
                          width: 348,
                          height: 45,
                          child: SvgPicture.string(
                            emotion.svg,
                            allowDrawingOutsideViewBox: true,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                // === BLOQUE 5 ===
                const SizedBox(height: 8),
                Stack(
                  children: [
                  SvgPicture.string(
                    '''
                <svg width="399" height="88" viewBox="0 0 399 88" fill="none" xmlns="http://www.w3.org/2000/svg">
                  <rect x="1.5" y="39.5" width="206" height="45" rx="14.5" stroke="#B4B1B8"/>
                  <rect y="1" width="208" height="32" fill="#010B19"/>
                  <rect x="310" width="85" height="32" fill="#010B19"/>
                  <rect x="18" y="46" width="173" height="32" fill="#010B19"/>
                </svg>
                    ''',
                    allowDrawingOutsideViewBox: true,
                  ),

                  // Texto en el rectángulo amarillo
                  const Positioned(
                    top: 5,
                    left: -10,
                    width: 208,
                    height: 32,
                    child: Center(
                      child: Text(
                        "You wanted to feel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFFE9E8EE),
                          fontFamily: 'EncodeSansExpanded',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Texto en el rectángulo celeste
                  const Positioned(
                    top: 5,
                    left: 260,
                    width: 85,
                    height: 32,
                    child: Center(
                      child: Text(
                        "Tracks",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:  Color(0XFFE9E8EE),
                          fontFamily: 'EncodeSansExpanded',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Texto en el rectángulo verde
                  const Positioned(
                    top: 44,
                    left: 10,
                    width: 173,
                    height: 32,
                    child: Center(
                      child: Text(
                        "Perseverance",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFFE9E8EE),
                          fontFamily: 'RobotoMono',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Carátulas dentro del rectángulo rojo
                  Positioned(
                    top: 38.5,
                    left: 205,
                    width: 150,
                    height: 49,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.5),
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF010B19),
                          border: Border.all(color: Color(0xFFB4B1B8)),
                          borderRadius: BorderRadius.circular(14.5),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.hardEdge,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(_albumCovers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      _albumCovers[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

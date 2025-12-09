<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Mail;


Route::get('/', function () {
    return view('welcome');
});

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::get('/test-email', function () {
    try {
        Mail::raw('Ceci est un e-mail de test pour vérifier MailHog.', function ($message) {
            $message->to('test@example.com')->subject('Test MailHog depuis le web');
        });
        return 'E-mail de test envoyé ! Vérifiez MailHog sur http://localhost:8025';
    } catch (\Exception $e) {
        return 'Erreur lors de l\'envoi de l\'e-mail : ' . $e->getMessage();
    }
});

require __DIR__.'/auth.php';

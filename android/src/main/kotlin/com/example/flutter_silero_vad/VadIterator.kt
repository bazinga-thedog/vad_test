package com.example.winamp;

interface VadIterator {
    fun predict(data: FloatArray): Boolean
    fun resetState()
}
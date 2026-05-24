package com.speechmate.general

import android.inputmethodservice.InputMethodService
import android.inputmethodservice.Keyboard
import android.inputmethodservice.KeyboardView
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection

class NicobareseInputMethodService : InputMethodService(), KeyboardView.OnKeyboardActionListener {
    private var keyboardView: KeyboardView? = null
    private var keyboard: Keyboard? = null
    private var isShifted = false

    override fun onCreateInputView(): View {
        // Inflate keyboard view with standard system layout
        keyboardView = layoutInflater.inflate(R.layout.keyboard_view, null) as KeyboardView?
        keyboard = Keyboard(this, R.xml.qwerty_nicobarese)
        keyboardView?.keyboard = keyboard
        keyboardView?.setOnKeyboardActionListener(this)
        return keyboardView!!
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        // Reset shift state on input start
        isShifted = false
        keyboard?.isShifted = false
        keyboardView?.invalidateAllKeys()
    }

    override fun onPress(primaryCode: Int) {}
    override fun onRelease(primaryCode: Int) {}

    override fun onKey(primaryCode: Int, keyCodes: IntArray?) {
        val inputConnection: InputConnection = currentInputConnection ?: return
        when (primaryCode) {
            Keyboard.KEYCODE_DELETE -> {
                inputConnection.deleteSurroundingText(1, 0)
            }
            Keyboard.KEYCODE_SHIFT -> {
                isShifted = !isShifted
                keyboard?.isShifted = isShifted
                keyboardView?.isShifted = isShifted
                keyboardView?.invalidateAllKeys()
            }
            Keyboard.KEYCODE_DONE, 10 -> {
                inputConnection.sendKeyEvent(android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, android.view.KeyEvent.KEYCODE_ENTER))
            }
            else -> {
                var codeChar = primaryCode.toChar()
                if (isShifted) {
                    codeChar = codeChar.uppercaseChar()
                }
                inputConnection.commitText(codeChar.toString(), 1)
            }
        }
    }

    override fun onText(text: CharSequence?) {
        val inputConnection: InputConnection = currentInputConnection ?: return
        inputConnection.commitText(text, 1)
    }

    override fun swipeLeft() {}
    override fun swipeRight() {}
    override fun swipeDown() {}
    override fun swipeUp() {}
}

package com.singularity.gaia.factory;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.view.Gravity;
import android.widget.TextView;

public final class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        TextView view = new TextView(this);
        view.setText("GAIA APP FACTORY\nANDROID GATE: ONLINE");
        view.setTextColor(Color.CYAN);
        view.setBackgroundColor(Color.rgb(1, 1, 3));
        view.setTextSize(22f);
        view.setGravity(Gravity.CENTER);
        setContentView(view);
    }
}

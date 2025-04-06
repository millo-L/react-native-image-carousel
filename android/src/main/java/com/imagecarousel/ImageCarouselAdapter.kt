package com.imagecarousel

import android.view.ViewGroup
import android.widget.ImageView
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide

class ImageCarouselAdapter(
    private val images: List<String>,
    private val multiplier: Int = 10000,
    private val onImageClick: (Int) -> Unit
) : RecyclerView.Adapter<ImageCarouselAdapter.ViewHolder>() {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val imageView = ImageView(parent.context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            scaleType = ImageView.ScaleType.CENTER_CROP
        }
        return ViewHolder(imageView)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val realPosition = position % images.size
        val imageUrl = images[realPosition]

        Glide.with(holder.imageView)
            .load(imageUrl)
            .into(holder.imageView)

        holder.imageView.setOnClickListener {
            onImageClick(realPosition)
        }
    }

    override fun getItemCount(): Int = if (images.isEmpty()) 0 else images.size * multiplier

    class ViewHolder(val imageView: ImageView) : RecyclerView.ViewHolder(imageView)
}
